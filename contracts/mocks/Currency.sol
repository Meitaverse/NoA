// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Currency is ERC20, Ownable, Pausable {
    
    using SafeERC20 for IERC20;

    uint8 private _decimals; 
    uint private TOTAL_SUPPLY = 100000000;

    event WithdrawToken(address indexed caller, address indexed to, uint256 indexed amount);

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    constructor() 
        ERC20('Currency', 'SBTCoin') 
   {
        _decimals = 18;
        _mint(address(this), TOTAL_SUPPLY * 1e8);
    }

    receive() external payable {}

    fallback() external payable {}

    function pause() external onlyOwner {
        _pause();
    }
    
    function unPause() external onlyOwner {
        _unpause();
    }

    function approve(address spender, uint amount)
       public
       override
       whenNotPaused
       returns (bool)
    {
       _approve(_msgSender(), spender, amount);
       return true;
    }

    function transferFrom(
       address sender,
       address recipient,
       uint amount
    )
       public
       override
       whenNotPaused
       returns (bool)
    {
       super.transferFrom(sender, recipient, amount);
       return true;
    }

    function increaseAllowance(
       address spender, 
       uint addedValue
    ) 
        public 
        virtual 
        override
        whenNotPaused
        returns (bool)
    {
       super.increaseAllowance(spender, addedValue);
       return true;
    }

    function decreaseAllowance(
       address spender, 
       uint subtractedValue
    ) 
        public 
        virtual 
        override
        whenNotPaused  
        returns (bool) 
    {
       super.decreaseAllowance(spender, subtractedValue);
       return true;
    }

    function withdraw()
       external
       onlyOwner
    {
        payable(_msgSender()).transfer(address(this).balance);
    }

    
  /**
  * @dev Withdraw SBT Token from this contract
  * @notice only owner can call this method
  */
  function withdrawToken(address to, uint256 amount) public onlyOwner returns(bool){
    uint256 _balance = balanceOf(address(this));
    if(_balance > amount) {
      IERC20(address(this)).safeTransfer(to, amount);
      emit WithdrawToken(msg.sender, to, amount);
    }
    return true; 
  }

}
