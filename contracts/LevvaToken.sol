// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract LevvaToken is ERC20, Ownable, ERC20Permit, ERC20Burnable {
  constructor(address initialOwner) ERC20('Levva', 'LVVA') Ownable(initialOwner) ERC20Permit('Levva') {
    uint256 oneToken = 10 ** decimals();

    _mint(address(0xb991d9E249961fd2300C4232ac306Edd41381494), 36_000_000 * oneToken); //36M Team
    _mint(address(0x941dbf5404Feb2D6831AaeA6F97aA9AEa87B3Bd3), 30_000_000 * oneToken); //30M Investors
    _mint(address(0x0EAEB48D8eF5b4e47cFa6C8496b7F20d62326A65), 10_000_000 * oneToken); //10M Sale
    _mint(address(0x8dD5C9A136E1AbD616620ab4EFdFBfeCfc28b180), 30_360_000 * oneToken); //30.36M Treasury
    _mint(address(0xBAB11696FcF11219F61051f5B143F98483BBb804), 50_000_000 * oneToken); //50M Incentives
    _mint(address(0x55f33E3dE879268d73874d05d17B05BFb7b5AEDA), 43_640_000 * oneToken); //43.64M Airdrop
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}
