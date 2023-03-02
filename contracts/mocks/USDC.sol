// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("Mockup USDC", "mUSDC") {
        _mint(msg.sender, 1000 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}
