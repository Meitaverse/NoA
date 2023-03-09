// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "../libraries/AdminRoleEnumerable.sol";

import {Errors} from "../libraries/Errors.sol";
import '../libraries/Constants.sol';
import {ERC3525Votes} from "../extensions/ERC3525Votes.sol";
import "../storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV2} from "../interfaces/INFTDerivativeProtocolTokenV2.sol";

/**
 *  @title dNFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV2 is
    Initializable,
    AdminRoleEnumerable,
    ERC3525Votes,
    SBTStorage,
    INFTDerivativeProtocolTokenV2
{
    //upgrade version
    uint256 internal constant VERSION = 2;
    uint256 public constant MAX_SUPPLY = 20000000000 * 1e18;
    bytes32 public constant TRANSFER_VALUE_ROLE = keccak256("TRANSFER_VALUE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 private treasury_SBT_ID;

    //New variables should be placed after all existing inherited variables
    address internal SIGNER;

    //===== Modifiers =====//
/**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }

    modifier onlyGov() {
        _validateCallerIsGov();
        _;
    }

    modifier onlyTransferRole() {
        require(hasRole(TRANSFER_VALUE_ROLE, msg.sender), "SBT: caller does not have the role");
        _;
    }

    modifier isTransferAllowed(uint256 tokenId_) {
        if(_sbtDetails[tokenId_].locked) revert Errors.Locked(); 
        _;
    }
    
    /**
     * @notice Adds the account to the list of approved operators.
     * @dev Only callable by admins as enforced by `grantRole`.
     * @param account The address to be approved.
     */
    function grantTransferRole(address account) external {
        grantRole(TRANSFER_VALUE_ROLE, account);
    }

    /**
     * @notice Removes the account from the list of approved operators.
     * @dev Only callable by admins as enforced by `revokeRole`.
     * @param account The address to be removed from the approved list.
     */
    function revokeFeeModule(address account) external {
        revokeRole(TRANSFER_VALUE_ROLE, account);
    }

    function setBankTreasury(address bankTreasury, uint256 amount) 
        external  
        onlyGov
    {
        total_supply += amount * 1e18;

        if (bankTreasury == address(0) || amount == 0 || total_supply > MAX_SUPPLY)
            revert Errors.InvalidParameter();
        
        _banktreasury = bankTreasury;

        if (treasury_SBT_ID == 0) {
            //create profile for bankTreasury, slot is 1, not vote power
            treasury_SBT_ID = 1;

            _createProfile(
                _banktreasury,
                treasury_SBT_ID,   
                "Bank Treasury",
                ""
            );
            
           ERC3525Upgradeable._mint(_banktreasury, 1, amount * 1e18);

        } else {
            //emit TransferValue
            ERC3525Upgradeable._mintValue(treasury_SBT_ID, amount * 1e18);
        }
    }
    
    function version() external pure returns(uint256) {
        return VERSION;
    }

    function createProfile(
        address voucher,
        DataTypes.CreateProfileData calldata vars
    ) 
        external 
        onlyManager  
        returns (uint256) 
    { 
        if (this.balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed(); 
        
        uint256 tokenId_ = _mint(vars.wallet, 1, 0);

        ERC3525Upgradeable._setApprovalForAll(vars.wallet, voucher, true);
        ERC3525Upgradeable._setApprovalForAll(vars.wallet, _banktreasury, true);
       
        _createProfile(
            vars.wallet,
            tokenId_,
            vars.nickName,
            vars.imageURI
        );

        return tokenId_;
    }

    function updateProfile(
        uint256 soulBoundTokenId,
        string calldata nickName,
        string calldata imageURI
    ) 
        external 
    { 
        if (msg.sender != ownerOf(soulBoundTokenId)) 
            revert Errors.NotOwner();

        _sbtDetails[soulBoundTokenId] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

        emit ProfileUpdated(
            soulBoundTokenId,
            nickName,
            imageURI
        );
    }

    function getProfileDetail(uint256 soulBoundTokenId) external view returns (DataTypes.SoulBoundTokenDetail memory){
        return _sbtDetails[soulBoundTokenId];
    }

    function burn(uint256 soulBoundTokenId) 
        external
    { 
        if (msg.sender != ownerOf(soulBoundTokenId)) 
            revert Errors.NotOwner();

        uint256 balance = this.balanceOf(soulBoundTokenId);

        if (balance > 0 ) {
            this.transferValue(soulBoundTokenId, BANK_TREASURY_SOUL_BOUND_TOKENID, balance);
        }
        
        delete _sbtDetails[soulBoundTokenId];

        ERC3525Upgradeable._burn(soulBoundTokenId);
    }

    function transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) 
        external  
        onlyTransferRole
    { 
        ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
    }

    //-- orverride -- //
    
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) 
        public 
        payable 
        virtual 
        override
        isTransferAllowed(tokenId_)  //Soul bound token can not transfer
    {
        super.transferFrom(from_, to_, tokenId_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override isTransferAllowed(fromTokenId_) returns (uint256) {
        return super.transferFrom(fromTokenId_, to_, value_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) 
        public 
        payable 
        virtual 
        override 
        isTransferAllowed(tokenId_) 
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC3525Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    } 

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setManager(address manager) internal {
        _manager = manager;
    }   
    function _setGovernance(address governance) internal {
        _governance = governance;
    }   

    function _validateCallerIsManager() internal view {
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    function _validateCallerIsGov() internal view {
        if (msg.sender != _governance) revert Errors.NotManager();
    }

    function _createProfile(
        address wallet_,
        uint256 tokenId_,
        string memory nickName,
        string memory imageURI
    ) internal {
        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: nickName,
            imageURI: imageURI,
            locked: true
        });

         emit ProfileCreated(
            tokenId_,
            tx.origin,
            wallet_,    
            nickName,
            imageURI
        );
    }
   
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
    
    //V2
    function setSigner(address signer) external {
        SIGNER = signer;
    }

    function getSigner() external view returns (address) {
        return SIGNER;
    }

}