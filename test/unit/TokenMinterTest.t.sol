// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from 'lib/forge-std/src/Test.sol';
import {Vm} from 'lib/forge-std/src/Vm.sol';
import {TokenMinter} from 'contracts/TokenMinter.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {LevvaToken} from 'contracts/LevvaToken.sol';

contract TokenMinterTest is Test {
  LevvaToken public token;
  TokenMinter public tokenMinter;

  address public OWNER = address(1);
  address public USER2 = address(2);

  address public OPERATOR1 = address(41);
  address public OPERATOR2 = address(42);
  address public OPERATOR3 = address(43);

  address public RECIPIENT1 = address(21);
  address public RECIPIENT2 = address(22);
  address public RECIPIENT3 = address(23);
  address public RECIPIENT4 = address(23);

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
    vm.warp(1742774400);

    token = new LevvaToken(OWNER);

    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT1, share: 73_33 * 10 ** 14}));
    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT2, share: 13_33 * 10 ** 14}));
    initialAllocations.push(TokenMinter.Allocation({recipient: RECIPIENT3, share: 13_34 * 10 ** 14}));

    tokenMinter = new TokenMinter(address(token), OWNER, weeklySchedule, initialAllocations);

    vm.startPrank(OWNER);
    vm.deal(OWNER, 1 ether);
    tokenMinter.addOperator(OPERATOR1, true);
    token.transferOwnership(address(tokenMinter));
    vm.stopPrank();
  }

  modifier fromOwner() {
    vm.startPrank(OWNER);
    vm.deal(OWNER, 1 ether);
    _;
  }

  modifier fromOperator() {
    vm.startPrank(OPERATOR1);
    vm.deal(OPERATOR1, 1 ether);
    _;
  }

  function testConstructorShouldFailWhenTokenAddressIsZero() public {
    // Arrange
    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidAddress.selector);
    new TokenMinter(address(0), OWNER, weeklySchedule, initialAllocations);
  }

  function testConstructorShouldFailWhenInitialOwnerIsZero() public {
    // Arrange
    // Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
    new TokenMinter(address(1), address(0), weeklySchedule, initialAllocations);
  }

  function testMint() public fromOperator {
    // Arrange
    uint256 balanceBefore1 = token.balanceOf(RECIPIENT1);
    uint256 balanceBefore2 = token.balanceOf(RECIPIENT2);
    uint256 balanceBefore3 = token.balanceOf(RECIPIENT3);
    uint256 mintCount = tokenMinter.getMintCount();
    TokenMinter.MintConfig memory mintConfig = tokenMinter.getMintConfig();

    uint256 expectedAllocation1 = 5288221152718000000000000;
    uint256 expectedAllocation2 = 961298076718000000000000;
    uint256 expectedAllocation3 = 962019230564000000000000;
    // Act
    vm.expectEmit(false, false, false, true, address(tokenMinter));
    emit TokenMinter.Mint(mintConfig.mintAmount, mintCount + 1);
    tokenMinter.mint();

    // Assert
    uint256 balanceDelta1 = token.balanceOf(RECIPIENT1) - balanceBefore1;
    uint256 balanceDelta2 = token.balanceOf(RECIPIENT2) - balanceBefore2;
    uint256 balanceDelta3 = token.balanceOf(RECIPIENT3) - balanceBefore3;

    assertEq(balanceDelta1, expectedAllocation1);
    assertEq(balanceDelta2, expectedAllocation2);
    assertEq(balanceDelta3, expectedAllocation3);
    assertEq(tokenMinter.getMintCount(), mintCount + 1);
    assertEq(tokenMinter.getLastMintTime(), block.timestamp);
    uint256 totalAllocated = balanceDelta1 + balanceDelta2 + balanceDelta3;
    assertEq(mintConfig.mintAmount, totalAllocated);
  }

  function testMintShouldFailWhenNotOperator() public {
    // Arrange
    vm.prank(OWNER);

    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__Unauthorized.selector);
    tokenMinter.mint();
  }

  function testMintShouldFailWhenAlreadyMintedInCurrentPeriod() public fromOperator {
    //Arrange
    tokenMinter.mint();
    //Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__MintNotAvailable.selector);
    tokenMinter.mint();
  }

  function testMintShouldFailWhenMaxCountOfMintsReached() public fromOperator {
    //Arrange
    vm.stopPrank();

    TokenMinter.MintConfig memory oneTimeMintConfig = tokenMinter.getMintConfig();
    oneTimeMintConfig.maxCountOfMints = 1;
    vm.prank(OWNER);
    tokenMinter.updateMintConfig(oneTimeMintConfig);

    vm.startPrank(OPERATOR1);
    tokenMinter.mint();
    //Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__MintNotAvailable.selector);
    tokenMinter.mint();
  }

  function testMintShouldFailWhenNotStarted() public {
    //Arrange
    vm.stopPrank();

    TokenMinter.MintConfig memory notStartedConfig = tokenMinter.getMintConfig();
    notStartedConfig.startTime += uint64(block.timestamp);

    vm.prank(OWNER);
    tokenMinter.updateMintConfig(notStartedConfig);

    vm.startPrank(OPERATOR1);
    //Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__MintNotAvailable.selector);
    tokenMinter.mint();
  }

  function testTransferTokenOwnershipShouldFailWhenNotOwner() public {
    //Arrange
    vm.prank(USER2);
    //Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER2));
    tokenMinter.transferTokenOwnership(USER2);
  }

  function testTransferTokenOwnershipShouldFailWhenNewOwnerIsZeroAddress() public fromOwner {
    //Arrange
    //Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidAddress.selector);
    tokenMinter.transferTokenOwnership(address(0));
  }

  function testTransferTokenOwnership() public fromOwner {
    //Arrange
    //Act
    tokenMinter.transferTokenOwnership(USER2);
    //Assert
    assertEq(token.owner(), USER2);
  }

  function testAddOperatorShouldFailWhenNotOwner() public {
    // Arrange
    vm.prank(USER2);
    // Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER2));
    tokenMinter.addOperator(USER2, true);
  }

  function testAddOperatorShouldFailWhenZeroAddress() public fromOwner {
    // Arrange
    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidAddress.selector);
    tokenMinter.addOperator(address(0), true);

    vm.expectRevert(TokenMinter.TokenMinter__InvalidAddress.selector);
    tokenMinter.addOperator(address(0), false);
  }

  function testAddOperatorShouldAddOperator() public fromOwner {
    // Arrange
    // Act
    vm.expectEmit(true, false, false, true, address(tokenMinter));
    emit TokenMinter.OperatorChanged(OPERATOR2, true);
    tokenMinter.addOperator(OPERATOR2, true);
    // Assert
    assertTrue(tokenMinter.isOperator(OPERATOR2));
  }

  function testAddOperatosShouldRemoveOperator() public fromOwner {
    // Arrange
    // Act
    vm.expectEmit(true, false, false, true, address(tokenMinter));
    emit TokenMinter.OperatorChanged(OPERATOR1, false);
    tokenMinter.addOperator(OPERATOR1, false);
    // Assert
    assertFalse(tokenMinter.isOperator(OPERATOR1));
  }

  function testUpdateAllocations() public fromOwner {
    //Arrange
    TokenMinter.Allocation[] memory newAllocations = new TokenMinter.Allocation[](2);
    newAllocations[0] = TokenMinter.Allocation({recipient: RECIPIENT4, share: 99 * 10 ** 16});
    newAllocations[1] = TokenMinter.Allocation({recipient: RECIPIENT3, share: 1 * 10 ** 16});
    TokenMinter.Allocation[] memory currentAllocations = tokenMinter.getAllocations();
    assertNotEq(currentAllocations.length, newAllocations.length);
    //Act
    tokenMinter.updateAllocations(newAllocations);
    //Assert
    TokenMinter.Allocation[] memory allocations = tokenMinter.getAllocations();
    assertEq(allocations.length, newAllocations.length);
    assertEq(allocations[0].recipient, newAllocations[0].recipient);
    assertEq(allocations[0].share, newAllocations[0].share);
    assertEq(allocations[1].recipient, newAllocations[1].recipient);
    assertEq(allocations[1].share, newAllocations[1].share);
  }

  function testUpdateAllocationsShouldFailWhenNotOwner() public {
    // Arrange
    vm.prank(USER2);
    // Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER2));
    tokenMinter.updateAllocations(initialAllocations);
  }

  function testUpdateAllocationsShouldFailWhenSharesNotEqualOne() public fromOwner {
    // Arrange
    TokenMinter.Allocation[] memory allocations = new TokenMinter.Allocation[](1);
    allocations[0] = TokenMinter.Allocation({recipient: RECIPIENT1, share: 1});

    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidShares.selector);
    tokenMinter.updateAllocations(allocations);
  }

  function testUpdateAllocationsShouldFailWhenRecipientAddressIsZero() public fromOwner {
    // Arrange
    TokenMinter.Allocation[] memory allocations = new TokenMinter.Allocation[](1);
    allocations[0] = TokenMinter.Allocation({recipient: address(0), share: 1});
    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidAddress.selector);
    tokenMinter.updateAllocations(allocations);
  }

  function testUpdateMintConfig() public fromOwner {
    // Arrange
    TokenMinter.MintConfig memory newConfig;
    newConfig.mintAmount = 1;
    newConfig.maxCountOfMints = 1;
    newConfig.periodLength = 1;
    newConfig.periodShift = 0;
    newConfig.startTime = 1;
    // Act
    tokenMinter.updateMintConfig(newConfig);
    // Assert
    TokenMinter.MintConfig memory updatedConfig = tokenMinter.getMintConfig();
    assertEq(updatedConfig.mintAmount, newConfig.mintAmount);
    assertEq(updatedConfig.maxCountOfMints, newConfig.maxCountOfMints);
    assertEq(updatedConfig.periodLength, newConfig.periodLength);
    assertEq(updatedConfig.periodShift, newConfig.periodShift);
    assertEq(updatedConfig.startTime, newConfig.startTime);
  }

  function testUpdateMintConfigShouldFailWhenNotOwner() public {
    // Arrange
    TokenMinter.MintConfig memory newConfig;
    vm.prank(USER2);
    // Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER2));
    tokenMinter.updateMintConfig(newConfig);
  }

  function testUpdateMintConfigShouldFailWhenPeriodLengthIsZero() public fromOwner {
    // Arrange
    TokenMinter.MintConfig memory newConfig;
    newConfig.startTime = 1;
    newConfig.periodLength = 0;
    // Act/Assert
    vm.expectRevert(TokenMinter.TokenMinter__InvalidMintConfig.selector);
    tokenMinter.updateMintConfig(newConfig);
  }

  function testGetToken() public view {
    // Arrange
    // Act
    address tokenAddress = tokenMinter.getToken();
    // Assert
    assertEq(tokenAddress, address(token));
  }

  function testGetMintConfig() public view {
    // Arrange
    // Act
    TokenMinter.MintConfig memory mintConfig = tokenMinter.getMintConfig();
    // Assert
    assertEq(mintConfig.mintAmount, weeklySchedule.mintAmount);
    assertEq(mintConfig.maxCountOfMints, weeklySchedule.maxCountOfMints);
    assertEq(mintConfig.periodLength, weeklySchedule.periodLength);
    assertEq(mintConfig.periodShift, weeklySchedule.periodShift);
    assertEq(mintConfig.startTime, weeklySchedule.startTime);
  }

  function testGetAllocations() public view {
    // Arrange
    // Act
    TokenMinter.Allocation[] memory allocations = tokenMinter.getAllocations();
    // Assert
    assertEq(allocations.length, initialAllocations.length);
    assertEq(allocations[0].recipient, initialAllocations[0].recipient);
    assertEq(allocations[0].share, initialAllocations[0].share);
    assertEq(allocations[1].recipient, initialAllocations[1].recipient);
    assertEq(allocations[1].share, initialAllocations[1].share);
    assertEq(allocations[2].recipient, initialAllocations[2].recipient);
    assertEq(allocations[2].share, initialAllocations[2].share);
  }

  function testGetLastMintTime() public view {
    // Arrange
    // Act
    uint256 lastMintTime = tokenMinter.getLastMintTime();
    // Assert
    assertEq(lastMintTime, 0);
  }

  function testGetMintCount() public view {
    // Arrange
    // Act
    uint32 mintCount = tokenMinter.getMintCount();
    // Assert
    assertEq(mintCount, 0);
  }

  function testIsOperator() public view {
    // Arrange
    // Act
    bool isOperator = tokenMinter.isOperator(OPERATOR1);
    bool isNotOperator = tokenMinter.isOperator(USER2);
    // Assert
    assertTrue(isOperator);
    assertFalse(isNotOperator);
  }

  function testCanMint() public view {
    // Arrange/Act
    bool canMint = tokenMinter.canMint();
    // Assert
    assertTrue(canMint);
  }
}
