// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from 'lib/forge-std/src/Test.sol';
import {Vm} from 'lib/forge-std/src/Vm.sol';
import {TokenMinter} from 'contracts/TokenMinter.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {LevvaToken} from 'contracts/LevvaToken.sol';

contract TokenMinterStagingTest is Test {
  LevvaToken public token = LevvaToken(0x6243558a24CC6116aBE751f27E6d7Ede50ABFC76);
  TokenMinter public tokenMinter;

  address public OWNER = 0x32764Ce6edBb6BF39A824cc95246375067c4573e;

  address public OPERATOR = address(41);

  address public RECIPIENT1 = 0xD20092A19e0488E1283E488e11583B43ba7EA849;
  address public RECIPIENT2 = 0x1D7e811aAbddDFd05a97A49C53645Db54deC0ac1;
  address public RECIPIENT3 = 0x4BB712660a5D16Fd38Bbf6Ede35235071B487dFD;

  TokenMinter.MintConfig public weeklySchedule =
    TokenMinter.MintConfig({
      startTime: 1742774400, // 2025-03-24 00:00:00
      periodLength: 604800, // 1 week
      periodShift: 345600, // 4 days to start on a Monday
      maxCountOfMints: 52,
      mintAmount: 7_211_538_46 * 10 ** 16 // 7_211_538,46 * 10^18
    });

  TokenMinter.Allocation[] public initialAllocations;

  function setUp() public {
    vm.skip(!isEthMainnet());
    vm.warp(weeklySchedule.startTime + 1);

    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT1, share: 73_33 * 10 ** 14}));
    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT2, share: 13_33 * 10 ** 14}));
    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT3, share: 13_34 * 10 ** 14}));

    tokenMinter = new TokenMinter(address(token), OWNER, weeklySchedule, initialAllocations);

    vm.startPrank(OWNER);
    vm.deal(OWNER, 1 ether);
    tokenMinter.addOperator(OPERATOR, true);
    token.transferOwnership(address(tokenMinter));
    vm.stopPrank();

    vm.deal(OPERATOR, 1 ether);
  }

  function isEthMainnet() public view returns (bool) {
    return block.chainid == 1;
  }

  function testMint() public {
    vm.startPrank(OPERATOR);

    TokenMinter.MintConfig memory config = tokenMinter.getMintConfig();
    uint256 totalMintedAmount = 0;

    uint256 balanceBefore1 = token.balanceOf(RECIPIENT1);
    uint256 balanceBefore2 = token.balanceOf(RECIPIENT2);
    uint256 balanceBefore3 = token.balanceOf(RECIPIENT3);

    for (uint256 i = 0; i < config.maxCountOfMints; i++) {
      tokenMinter.mint();

      vm.warp(block.timestamp + config.periodLength + 1);
      vm.roll(block.number + 1);
    }

    uint256 balanceAfter1 = token.balanceOf(RECIPIENT1);
    uint256 balanceAfter2 = token.balanceOf(RECIPIENT2);
    uint256 balanceAfter3 = token.balanceOf(RECIPIENT3);

    totalMintedAmount =
      balanceAfter1 -
      balanceBefore1 +
      balanceAfter2 -
      balanceBefore2 +
      balanceAfter3 -
      balanceBefore3;

    assertEq(totalMintedAmount, config.mintAmount * config.maxCountOfMints);

    vm.stopPrank();
  }

  function testMintWithSkipPeriods() public {
    vm.startPrank(OPERATOR);

    TokenMinter.MintConfig memory config = tokenMinter.getMintConfig();
    uint256 totalMintedAmount = 0;

    uint256 balanceBefore1 = token.balanceOf(RECIPIENT1);
    uint256 balanceBefore2 = token.balanceOf(RECIPIENT2);
    uint256 balanceBefore3 = token.balanceOf(RECIPIENT3);

    uint256 periodCounter = 0;
    uint256 mintCount = tokenMinter.getMintCount();
    while (mintCount < config.maxCountOfMints) {
      if (periodCounter % 2 == 0) {
        tokenMinter.mint();
      }

      vm.warp(block.timestamp + config.periodLength + 1);
      vm.roll(block.number + 1);

      mintCount = tokenMinter.getMintCount();
      periodCounter++;
    }

    uint256 balanceAfter1 = token.balanceOf(RECIPIENT1);
    uint256 balanceAfter2 = token.balanceOf(RECIPIENT2);
    uint256 balanceAfter3 = token.balanceOf(RECIPIENT3);

    totalMintedAmount =
      balanceAfter1 -
      balanceBefore1 +
      balanceAfter2 -
      balanceBefore2 +
      balanceAfter3 -
      balanceBefore3;

    assertEq(totalMintedAmount, config.mintAmount * config.maxCountOfMints);

    vm.stopPrank();
  }
}
