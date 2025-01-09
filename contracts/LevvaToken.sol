// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';

contract LevvaToken is ERC20, Ownable, ERC20Permit, ERC20Burnable {
  error MaxSupplyExceeded();

  uint256 public constant MAX_SUPPLY = 2_000_000_000e18;

  constructor(address initialOwner) ERC20('Levva Protocol Token', 'LVVA') Ownable(initialOwner) ERC20Permit('Levva') {
    _mint(address(0xAFbFb590D65d7E8E15532217e59A48A751a81361), 1_000_000_000e18); //1B Swap
    _mint(address(0x9D62FF0aBA56A4633861565DF657c759631Fb83C), 62_500_000e18); //62.5M Token Sale
    _mint(address(0xdcf1683a80259d09228CC24DfC061cC03A635614), 62_500_000e18); //62.5M Airdrop
    _mint(address(0x97B7A89C8f80CA87bD718Fc3c667f43a17f82B11), 125_000_000e18); //125M Treasury
  }

  function mint(address to, uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= MAX_SUPPLY, MaxSupplyExceeded());
    _mint(to, amount);
  }
}
