// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@solvprotocol/erc-3525/contracts/ERC3525Upgradeable.sol";
import "./libraries/AdminRoleEnumerable.sol";
import {IManager} from "./interfaces/IManager.sol";
import "@solvprotocol/erc-3525/contracts/IERC3525.sol";
import {Errors} from "./libraries/Errors.sol";
import './libraries/Constants.sol';
import "./storage/ProjectFounderStorage.sol";
// import "hardhat/console.sol";

/**
 *  @title Project Founder Token base ERC-3525
 * 
 */
contract ProjectFounder is
    Initializable,
    AdminRoleEnumerable,
    ProjectFounderStorage,
    ERC3525Upgradeable
{
    uint256 internal constant VERSION = 1;


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

    //===== Initializer =====//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string calldata name,
        string calldata symbol,
        address manager,
        address governance,
        address sbt,
        address metadataDescriptor_
    ) external initializer {
        //decimals is set to 0
        __ERC3525_init_unchained(name, symbol, 0); 
        AdminRoleEnumerable._initializeAdminRole(governance);

        if (    manager == address(0x0) || 
                governance == address(0x0) || 
                metadataDescriptor_ == address(0x0)
            ) 
            revert Errors.InitParamsInvalid();

        _setManager(manager);

        _setSBT(sbt);

        _setGovernance(governance);

        _setMetadataDescriptor(metadataDescriptor_);
    }
    

    function setBankTreasury(address bankTreasury) 
        external  
        onlyGov
    {

        if (bankTreasury == address(0))
            revert Errors.InvalidParameter();
        
        _banktreasury = bankTreasury;


    }
    
    function version() external pure returns(uint256) {
        return VERSION;
    }
    
    function mint(uint256 projectId) external returns(uint256) {

        DataTypes.ProjectData memory info = IManager(_manager).getProjectInfo(projectId);
        uint256 soulBoundTokenId = info.soulBoundTokenId;

        if (soulBoundTokenId == 0) {
            revert Errors.TokenIsNotSoulBound();
        }
        address projectOwner = IERC3525(_sbt).ownerOf(soulBoundTokenId);
        if (projectOwner == address(0)) {
                revert Errors.TokenIsNotSoulBound();
        }
        if (msg.sender != projectOwner) {
            revert Errors.NotProjectOwner();
        } 

        if (_projectTokens[projectId] == projectOwner)  revert Errors.TokenIsClaimed(); 
        
        //slot is set to projectId
         uint256 tokenId = _mint(projectOwner, projectId, BASIS_POINTS);

         _projectTokens[projectId] = projectOwner;

         return tokenId;
      
    }
   
    function burn(uint256 tokenId) external onlyGov
    { 
        ERC3525Upgradeable._burn(tokenId);
    }

    //-- orverride -- //
 
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC3525Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    } 

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _setManager(address manager) internal {
        _manager = manager;
    }   

    function _setSBT(address sbt) internal {
        _sbt = sbt;
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
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}