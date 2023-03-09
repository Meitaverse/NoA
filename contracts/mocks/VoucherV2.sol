// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author:Bitsoul Protocol

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";

import "../creatorCore/ERC1155CreatorCore.sol";
import '../libraries/Constants.sol';
import {Errors} from "../libraries/Errors.sol";

/**
 * @dev ERC1155Creator implementation (using transparent upgradeable proxy)
 */
contract VoucherV2 is 
    AdminControlUpgradeable, 
    ERC1155Upgradeable, 
    ERC1155CreatorCore
{

    /**
     * @dev Emitted when a voucher is minted
     *
     * @param preUserAmountLimit  The pre userAmountLimit
     * @param userAmountLimit The new userAmountLimit
     */
    event UserAmountLimitSet(
        uint256 preUserAmountLimit,
        uint256 userAmountLimit
    );

    /**
     * @dev Emitted when a voucher is generated
     *
     * @param soulBoundTokenId The SBT id of tx.origin
     * @param totalAmount The total value of SBT
     * @param to The array of to
     * @param amounts The array of amount
     * @param uris The array of uri
     * @param tokenIds The array of new tokenId
     */
    event GenerateVoucher(
        uint256 indexed soulBoundTokenId,
        uint256 indexed totalAmount,
        address[] to,
        uint256[] amounts,
        string[] uris,
        uint256[] tokenIds
    );

    /**
     * @dev Emitted when a tokenUri is set
     *
     * @param tokenId The token id of voucher
     * @param uri The uri
     */
    event TokenURISet(
        uint256 indexed tokenId,
        string indexed uri
    );

    mapping(uint256 => uint256) private _totalSupply;
    uint256 private _userAmountLimit;

    address internal sbt;
    address internal treasury;

    uint256 internal _additionalValue;


    modifier onlySBTUser(uint256 soulBoundTokenId_) {
        _validateCallerIsSoulBoundTokenOwner(soulBoundTokenId_);
        _;
    }

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {}  
    // /**
    //  * Initializer
    //  */
    // function initialize(
    //     address _sbt,
    //     address _treasury,
    //     string memory _name, 
    //     string memory _symbol
    // ) public initializer {
    //     __ERC1155_init("");
    //     __Ownable_init();
    //     // __Pausable_init();
    //     __Core_init();
    //     sbt = _sbt;
    //     treasury = _treasury;
    //     name = _name;
    //     symbol = _symbol;
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC1155CreatorCore, AdminControlUpgradeable) returns (bool) {
        return ERC1155CreatorCore.supportsInterface(interfaceId) || 
               ERC1155Upgradeable.supportsInterface(interfaceId) || 
               AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) internal virtual override {
        _approveTransfer(from, to, ids, amounts);
    }

    function setUserAmountLimit(uint256 userAmountLimit) external onlyOwner {
        if (userAmountLimit == 0) revert Errors.InvalidParameter();
        uint256 preUserAmountLimit = _userAmountLimit;
        _userAmountLimit = userAmountLimit;
        emit UserAmountLimitSet(preUserAmountLimit, _userAmountLimit);
    }
    
    function getUserAmountLimit() external view returns(uint256) {
        return _userAmountLimit;
    }
    
    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, baseURIIdentical);
    }

    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri_, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri_, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri_) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override {
        requireExtension();
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri_) external override adminRequired {
        _setBaseTokenURI(uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {
        _setTokenURI(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseNew}.
     */
    function mintBaseNew(uint256 soulBoundTokenId, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) 
        public 
        virtual 
        override 
        nonReentrant 
        onlySBTUser(soulBoundTokenId)
        returns(uint256[] memory) 
    {
        uint256 totalAmount;
        for (uint i; i < to.length;) {
            if (_userAmountLimit > 0 ){
                if (amounts[i] < _userAmountLimit) {
                    revert Errors.AmountSBTIsZero();
                }
            }              
            totalAmount += amounts[i];
            unchecked { ++i; }
        }        
        
        //owner of soulBoundTokenId need to approve this contract first
        IERC3525(sbt).transferFrom(
            soulBoundTokenId, 
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            totalAmount
        );

        uint256[] memory tokenIds = _mintNew(soulBoundTokenId, totalAmount, address(0), to, amounts, uris);
        
        setApprovalForAll(treasury, true);
        
        return tokenIds; 
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionNew}.
     */
    function mintExtensionNew(uint256 soulBoundTokenId, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) 
        public 
        virtual 
        override 
        nonReentrant 
        // whenNotPaused 
        onlySBTUser(soulBoundTokenId)
        returns(uint256[] memory tokenIds) 
    {
        requireExtension();

        uint256 totalAmount;
        for (uint i; i < to.length;) {
            if (_userAmountLimit > 0 ){
                if (amounts[i] < _userAmountLimit) {
                    revert Errors.AmountSBTIsZero();
                }
            }              
            totalAmount += amounts[i];
            unchecked { ++i; }
        }
        
        //need to approve this contract first by owner of soulBoundTokenId
        IERC3525(sbt).transferFrom(
            soulBoundTokenId, 
            BANK_TREASURY_SOUL_BOUND_TOKENID, 
            totalAmount
        );

        tokenIds = _mintNew(soulBoundTokenId, totalAmount, msg.sender, to, amounts, uris);

    }

    /**
     * @dev Mint new tokens
     */
    function _mintNew(uint256 soulBoundTokenId, uint256 totalAmount, address extension, address[] memory to, uint256[] memory amounts, string[] memory uris) internal returns(uint256[] memory tokenIds) {
        if (to.length > 1) {
            // Multiple receiver.  Give every receiver the same new token
            tokenIds = new uint256[](1);
            require(uris.length <= 1 && (amounts.length == 1 || to.length == amounts.length), "Invalid input");
        } else {
            // Single receiver.  Generating multiple tokens
            tokenIds = new uint256[](amounts.length);
            require(uris.length == 0 || amounts.length == uris.length, "Invalid input");
        }

        // Assign tokenIds
        for (uint i; i < tokenIds.length;) {
            ++_tokenCount;
            tokenIds[i] = _tokenCount;
            // Track the extension that minted the token
            _tokensExtension[_tokenCount] = extension;
            unchecked { ++i; }
        }

        if (extension != address(0)) {
            _checkMintPermissions(to, tokenIds, amounts);
        }

        if (to.length == 1 && tokenIds.length == 1) {
            // Single mint
            _mint(to[0], tokenIds[0], amounts[0], new bytes(0));
        } else if (to.length > 1) {
            // Multiple receivers.  Receiving the same token
            if (amounts.length == 1) {
                // Everyone receiving the same amount
                for (uint i; i < to.length;) {
                    _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
                    unchecked { ++i; }
                }
            } else {
                // Everyone receiving different amounts
                for (uint i; i < to.length;) {                  
                    _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
                    
                    unchecked { ++i; }
                }
            }
        } else {
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        }

        for (uint i; i < tokenIds.length;) {
            if (i < uris.length && bytes(uris[i]).length > 0) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
            unchecked { ++i; }
        }
         
        emit GenerateVoucher(
             soulBoundTokenId,
             totalAmount,
             to,
             amounts,
             uris,
             tokenIds 
        );
    }

    /**
     * @dev See {IERC1155CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address) {
        return _tokenExtension(tokenId);
    }

    /**
     * @dev See {IERC1155CreatorCore-burn}.
     */
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual override nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner nor approved");
        require(tokenIds.length == amounts.length, "burn: Invalid input");
        if (tokenIds.length == 1) {
            _burn(account, tokenIds[0], amounts[0]);
        } else {
            _burnBatch(account, tokenIds, amounts);
        }
        _postBurn(account, tokenIds, amounts);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURI(tokenId);
    }
    
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint i; i < ids.length;) {               
            _totalSupply[ids[i]] += amounts[i];
            unchecked { ++i; }
        }
        setApprovalForAll(treasury, true);
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] -= amounts[i];
            unchecked { ++i; }
        }
    }
    /**
     * @dev Set token uri for a token with no extension
     */
    function _setTokenURI(uint256 tokenId, string calldata uri_) internal virtual override{
       super._setTokenURI(tokenId, uri_);

       emit TokenURISet(tokenId, uri_);
    }
    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
    }

        
    function _validateCallerIsSoulBoundTokenOwner(uint256 soulBoundTokenId_) internal view {
        
         if (IERC3525(sbt).ownerOf(soulBoundTokenId_) == tx.origin) {
            return;
         }

         revert Errors.NotProfileOwner();
    }

    //V2

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function version() external pure  returns (uint256) {
        return 2;
    }
}