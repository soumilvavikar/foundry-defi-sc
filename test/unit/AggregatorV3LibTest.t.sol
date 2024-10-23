// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {AggregatorV3Lib, AggregatorV3Interface} from "../../src/libs/AggregatorV3Lib.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";

/**
 * @title AggregatorV3LibTest
 * @author Soumil Vavikar
 * @notice Test the AggregatorV3Lib library
 */
contract AggregatorV3LibTest is StdCheats, Test {
    // Using AggregatorV3Lib for AggregatorV3Interface
    using AggregatorV3Lib for AggregatorV3Interface;

    MockV3Aggregator public aggregator;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITAL_PRICE = 2000 ether;

    /**
     * @notice Setup the test
     */
    function setUp() public {
        aggregator = new MockV3Aggregator(DECIMALS, INITAL_PRICE);
    }

    /**
     * @notice Test the get Timeout function
     */
    function testGetTimeout() public view {
        uint256 expectedTimeout = 3 hours;
        assertEq(AggregatorV3Lib.getTimeout(AggregatorV3Interface(address(aggregator))), expectedTimeout);
    }

    /**
     * Test the function revert on stale check
     */
    function testPriceRevertsOnStaleCheck() public {
        vm.warp(block.timestamp + 4 hours + 1 seconds);
        vm.roll(block.number + 1);

        vm.expectRevert(SV15CErrors.AggregatorV3Lib__StalePrice.selector);
        AggregatorV3Interface(address(aggregator)).staleCheckLatestRoundData();
    }

    /**
     * Test the function for the negative test case, and expect a revert
     */
    function testPriceRevertsOnBadAnsweredInRound() public {
        uint80 _roundId = 0;
        int256 _answer = 0;
        uint256 _timestamp = 0;
        uint256 _startedAt = 0;
        aggregator.updateRoundData(_roundId, _answer, _timestamp, _startedAt);

        vm.expectRevert(SV15CErrors.AggregatorV3Lib__StalePrice.selector);
        AggregatorV3Interface(address(aggregator)).staleCheckLatestRoundData();
    }
}
