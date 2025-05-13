// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from 'lib/forge-std/src/Test.sol';
import {Vm} from 'lib/forge-std/src/Vm.sol';

contract CurrentPeriodTest is Test {
  function getCurrentPeriod(
    uint256 timestamp,
    uint256 periodLength,
    uint256 periodOffset
  ) public pure returns (uint256) {
    return timestamp - ((timestamp - periodOffset) % periodLength);
  }

  function testGetCurrentPeriod() public pure {
    uint256 periodLength = 604800; // 1 week
    uint256 periodOffset = 4 * 86400; // 4 days
    uint256 expectedPeriod = 1742774400; //Mon Mar 24 2025 00:00:00 GMT+0000
    uint256 expectedNextPeriod = expectedPeriod + periodLength;

    // 1742774400 Mon Mar 24 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1742774400, periodLength, periodOffset));

    // 1742860800 Tue Mar 25 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1742860800, periodLength, periodOffset));

    // 1742947200 Wed Mar 26 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1742947200, periodLength, periodOffset));

    // 1743033600 Thu Mar 27 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1743033600, periodLength, periodOffset));

    // 1743120000 Fri Mar 28 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1743120000, periodLength, periodOffset));

    // 1743120000 Sat Mar 29 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1743206400, periodLength, periodOffset));

    // 1743292800 Sun Mar 30 2025 00:00:00 GMT+0000
    assertEq(expectedPeriod, getCurrentPeriod(1743292800, periodLength, periodOffset));

    // 1743379200 Mon Mar 31 2025 00:00:00 GMT+0000
    assertEq(expectedNextPeriod, getCurrentPeriod(1743379200, periodLength, periodOffset));
  }
}
