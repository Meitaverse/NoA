// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@solvprotocol/erc-3525/contracts/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
// import "@solvprotocol/erc-3525/contracts/IERC3525Receiver.sol";
import "@solvprotocol/erc-3525/contracts/extensions/IERC3525Metadata.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {Constants} from '../libraries/Constants.sol';
import {IManager} from "../interfaces/IManager.sol";
import {ERC3525Votes} from "../extensions/ERC3525Votes.sol";
import "../storage/SBTStorage.sol";
import {INFTDerivativeProtocolTokenV2} from "../interfaces/INFTDerivativeProtocolTokenV2.sol";

/**
 *  @title NFT Derivative Protocol Token
 */
contract NFTDerivativeProtocolTokenV2 is
    Initializable,
    // ReentrancyGuard,
    // AccessControlUpgradeable,
    // PausableUpgradeable,
    ERC3525Votes,
    SBTStorage,
    INFTDerivativeProtocolTokenV2,
    // ERC3525SlotEnumerableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 internal constant VERSION = 2;
    uint256 public constant MAX_SUPPLY = 100000000 * 1e18;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address internal SIGNER;
    //===== Modifiers =====//

    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyManager() {
        _validateCallerIsManager();
        _;
    }

    modifier isTransferAllowed(uint256 tokenId_) {
        if (_sbtDetails[tokenId_].locked) revert Errors.Locked();
        _;
    }

    function version() external pure returns (uint256) {
        return VERSION;
    }

    // function pause() public onlyRole(PAUSER_ROLE) {
    //     _pause();
    // }

    // function unpause() public onlyRole(PAUSER_ROLE) {
    //     _unpause();
    // }

    // function isContractWhitelisted(address contract_) external view override returns (bool) {
    //     return _contractWhitelisted[contract_];
    // }

    function whitelistContract(address contract_, bool toWhitelist_) external {
        //nonReentrant
        // if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();
        _whitelistContract(contract_, toWhitelist_);
    }

    function _whitelistContract(address contract_, bool toWhitelist_) internal {
        if (contract_ == address(0)) revert Errors.InitParamsInvalid();
        bool prevWhitelisted = _contractWhitelisted[contract_];
        _contractWhitelisted[contract_] = toWhitelist_;
        emit Events.SetContractWhitelisted(contract_, prevWhitelisted, toWhitelist_, block.timestamp);
    }

    function createProfile(
        address creator,
        DataTypes.CreateProfileData calldata vars
    )
        external
        // whenNotPaused
        onlyManager
        returns (uint256)
    {
        //nonReentrant
        _validateNickName(vars.nickName);

        if (balanceOf(vars.wallet) > 0) revert Errors.TokenIsClaimed();

        uint256 tokenId_ = ERC3525Upgradeable._mint(vars.wallet, 1, 0);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({
            nickName: vars.nickName,
            imageURI: vars.imageURI,
            locked: true
        });

        emit Events.ProfileCreated(tokenId_, creator, vars.wallet, vars.nickName, vars.imageURI, block.timestamp);

        return tokenId_;
    }

    function mintValue(
        uint256 soulBoundTokenId,
        uint256 value
    )
        external
        payable
        // whenNotPaused
        onlyManager
    {
        //nonReentrant
        if (value == 0) revert Errors.InvalidParameter();

        total_supply += value;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        ERC3525Upgradeable._mintValue(soulBoundTokenId, value);
        emit Events.MintSBTValue(soulBoundTokenId, value, block.timestamp);
    }

    function burn(
        uint256 tokenId
    )
        external
        // whenNotPaused
        onlyManager
    {
        //nonReentrant
        ERC3525Upgradeable._burn(tokenId);
        emit Events.BurnSBT(tokenId, block.timestamp);
    }

    function burnValue(
        uint256 tokenId,
        uint256 value
    )
        external
        // whenNotPaused
        onlyManager
    {
        //nonReentrant
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC3525: caller is not token owner nor approved");
        ERC3525Upgradeable._burnValue(tokenId, value);
        emit Events.BurnSBTValue(tokenId, value, block.timestamp);
    }

    function transferValue(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) external {
        //nonReentrant
        //call only by BankTreasury or FeeCollectModule or publishModule  or Voucher
        if (_contractWhitelisted[msg.sender]) {
            ERC3525Upgradeable._transferValue(fromTokenId_, toTokenId_, value_);
            return;
        }
        revert Errors.NotTransferValueAuthorised();
    }

    //-- orverride -- //

    // The functions below are overrides required by Solidity.

    //   function _afterTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 amount
    //   ) internal override(ERC3525Upgradeable, ERC3525Votes) {
    //     super._afterTokenTransfer(from, to, amount);
    //   }

    //   function _mint(address to, uint256 amount) internal override(ERC3525Upgradeable, ERC3525Votes) {
    //     super._mint(to, amount);
    //   }

    function _mint(
        address to_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Votes) returns (uint256) {
        super._mint(to_, slot_, value_);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual override(ERC3525Votes) {
        super._burnValue(tokenId_, burnValue_);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Votes) {
        super._afterValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525Upgradeable) {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    )
        public
        payable
        virtual
        override
        // nonReentrant
        // whenNotPaused
        isTransferAllowed(tokenId_) //Soul bound token can not transfer
    {
        super.transferFrom(from_, to_, tokenId_);
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
        // nonReentrant
        // whenNotPaused
        isTransferAllowed(tokenId_)
    {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    // function setApprovalForSlot(
    //     address owner_,
    //     uint256 slot_,
    //     address operator_,
    //     bool approved_
    // )
    //     external
    //     payable
    //     virtual
    //     // nonReentrant
    //     // whenNotPaused
    // {
    //     if (!(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()))) {
    //         revert Errors.NotAllowed();
    //     }
    //     _setApprovalForSlot(owner_, slot_, operator_, approved_);
    // }

    // function isApprovedForSlot(address owner_, uint256 slot_, address operator_) external view virtual returns (bool) {
    //     return _slotApprovals[owner_][slot_][operator_];
    // }

    // function _setApprovalForSlot(address owner_, uint256 slot_, address operator_, bool approved_) internal virtual {
    //     if (owner_ == operator_) {
    //         revert Errors.ApproveToOwner();
    //     }
    //     _slotApprovals[owner_][slot_][operator_] = approved_;
    //     emit Events.ApprovalForSlot(owner_, slot_, operator_, approved_);
    // }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC3525Upgradeable) returns (bool) {
        return
            // interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //V1
    // function getManager() external view returns (address) {
    //     return _manager;
    // }

    function setBankTreasury(address bankTreasury, uint256 initialSupply) external // nonReentrant
    // whenNotPaused
    {
        // if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) revert Errors.Unauthorized();

        if (bankTreasury == address(0)) revert Errors.InvalidParameter();
        if (initialSupply == 0) revert Errors.InvalidParameter();
        if (_banktreasury != address(0)) revert Errors.InitialIsAlreadyDone();
        _banktreasury = bankTreasury;

        total_supply += initialSupply;
        if (total_supply > MAX_SUPPLY) revert Errors.MaxSupplyExceeded();

        //create profile for bankTreasury, tokenId is 1
        uint256 tokenId_ = ERC3525Upgradeable._mint(_banktreasury, 1, initialSupply);
        ERC3525Upgradeable.setApprovalForAll(_banktreasury, true);

        _sbtDetails[tokenId_] = DataTypes.SoulBoundTokenDetail({nickName: "Bank Treasury", imageURI: "", locked: true});

        emit Events.ProfileCreated(tokenId_, _msgSender(), _banktreasury, "bank treasury", "", block.timestamp);

        emit Events.BankTreasurySet(tokenId_, bankTreasury, initialSupply, block.timestamp);
    }

    // function getBankTreasury() external view returns (address) {
    //     return _banktreasury;
    // }

    // function setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI) external override // nonReentrant
    // // whenNotPaused
    // {
    //     _validateCallerIsSoulBoundTokenOwnerOrDispathcher(soulBoundTokenId);

    //     _setProfileImageURI(soulBoundTokenId, imageURI);
    // }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setManager(address manager) internal {
        _manager = manager;
    }

    function _validateCallerIsSoulBoundTokenOwnerOrDispathcher(uint256 soulBoundTokenId_) internal view {
        if (
            ownerOf(soulBoundTokenId_) == msg.sender ||
            IManager(_manager).getDispatcher(soulBoundTokenId_) == msg.sender
        ) {
            return;
        }

        revert Errors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsManager() internal view {
        if (msg.sender != _manager) revert Errors.NotManager();
    }

    //-- orverride -- //
    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override {
        // if (!hasRole(UPGRADER_ROLE, _msgSender())) revert Errors.Unauthorized();
    }

    // function _setProfileImageURI(uint256 soulBoundTokenId, string calldata imageURI) internal {
    //     if (bytes(imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
    //         revert Errors.ProfileImageURILengthInvalid();

    //     DataTypes.SoulBoundTokenDetail storage detail = _sbtDetails[soulBoundTokenId];
    //     detail.imageURI = imageURI;

    //     emit Events.ProfileImageURISet(soulBoundTokenId, imageURI, block.timestamp);
    // }

    function _validateNickName(string calldata nickName) private pure {
        bytes memory byteNickName = bytes(nickName);
        if (byteNickName.length == 0 || byteNickName.length > Constants.MAX_NICKNAME_LENGTH)
            revert Errors.NickNameLengthInvalid();
    }

    //V2
    function setSigner(address signer) external {
        SIGNER = signer;
    }

    function getSigner() external view returns (address) {
        return SIGNER;
    }


}