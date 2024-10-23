// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SV15CErrors} from "./SV15CErrors.sol";
/*
 * @title AggregatorV3Lib
 * @author Soumil Vavikar
 * @notice This library is used to check the Chainlink Oracle for stale data.
 * 
 * If a price is stale, functions will revert, and render the DSCEngine unusable - this is by design.
 * We want the DSCEngine to freeze if prices become stale.
 *
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol... too bad.
 */

library AggregatorV3Lib {
    uint256 private constant AGG_V3_TIMEOUT = 3 hours; //10800 seconds

    /**
     * This function will check if the price returned by the AggregatorV3Interface is stale
     *
     * @param chainlinkFeed the aggregatorV3 interface
     * @return roundId - The round ID from the latest round
     * @return answer - The price from the latest round
     * @return startedAt - Timestamp when the round started
     * @return updatedAt - Timestamp when the round was updated
     * @return answeredInRound - The round ID when the answer was computed
     */
    function staleCheckLatestRoundData(AggregatorV3Interface chainlinkFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // Get the latest round data
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            chainlinkFeed.latestRoundData();

        // Check if the price is stale, if the updatedAt is 0 or the answeredInRound is less than the roundId
        if (updatedAt == 0 || answeredInRound < roundId) {
            revert SV15CErrors.AggregatorV3Lib__StalePrice();
        }
        // Check if the price is older than the timeout
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > AGG_V3_TIMEOUT) revert SV15CErrors.AggregatorV3Lib__StalePrice();

        // Return the round data
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    /**
     * This function will return the timeout value
     *
     * @return uint256 - the timeout value
     */
    function getTimeout(AggregatorV3Interface /* chainlinkFeed */ ) public pure returns (uint256) {
        return AGG_V3_TIMEOUT;
    }
}
