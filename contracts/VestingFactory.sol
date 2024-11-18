// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {VestingWallet} from '@openzeppelin/contracts/finance/VestingWallet.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

///@notice Ownable vesting wallet factory. Before vesting tokenHolder should approve spending sum(amounts) of tokens
contract VestingWalletFactory is Ownable {
  event VestingWalletCreated(address indexed wallet, address indexed beneficiary);

  constructor(address initialOwner) Ownable(initialOwner) {}

  function createVestingWallets(
    address[] calldata users,
    uint256[] calldata vestingAmounts,
    uint256[] calldata amounts,
    address token,
    address tokenHolder,
    uint64 startTimestamp,
    uint64 durationSeconds
  ) external onlyOwner {
    require(token != address(0), 'Zero address');
    require(tokenHolder != address(0), 'Zero address');
    require(users.length == vestingAmounts.length, 'Invalid vesting amounts length');
    require(users.length == amounts.length, 'Invalid amounts length');

    uint256 index;
    uint256 lenght = users.length;
    for (; index < lenght; ) {
      address beneficiary = users[index];
      uint256 vestginAmount = vestingAmounts[index];

      require(beneficiary != address(0), 'Zero address');
      require(vestginAmount != 0, 'Invalid amount');

      VestingWallet wallet = new VestingWallet(beneficiary, startTimestamp, durationSeconds);
      SafeERC20.safeTransferFrom(IERC20(token), tokenHolder, address(wallet), vestginAmount);

      emit VestingWalletCreated(address(wallet), beneficiary);

      uint256 amount = amounts[index];
      if (amount != 0) {
        SafeERC20.safeTransferFrom(IERC20(token), tokenHolder, beneficiary, amount);
      }

      unchecked {
        ++index;
      }
    }
  }
}
