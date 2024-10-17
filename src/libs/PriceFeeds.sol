// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {SV15CConstants} from "./SV15CConstants.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {console} from "forge-std/console.sol";

/**
 * @title PriceFeeds
 * @author Soumil Vavikar
 * @notice Library for price feeds
 */
library PriceFeeds {
    /**
     * This function returns the USD value of a given amount of tokens.
     *
     * @param priceFeedAddress The address of the price feed
     * @param amountOfTokens The amount of tokens to get the USD value for
     */
    function getUsdValueOfToken(address priceFeedAddress, uint256 amountOfTokens)
        internal
        view
        returns (uint256 usdValueOfToken)
    {
        console.log("priceFeedAddress: ", priceFeedAddress);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price,,,) = priceFeed.latestRoundData();
        /**
         * IMPORTANT:
         *  - Most USD pairs have 8 decimals, so we will just pretend they all do
         *  - To make calculations easier, we would have everything in terms of WEI
         *
         * If 1 ETH = 2000 USD and 1 ETH = 1e18 WEI
         * price returned from price feed = 2000 * 1e8 = 2000e8
         * additional feed precision = 1e10
         *
         * price * additional feed precision = 2000e18
         *
         * precision = nothing BUT ETH to WEI conversion. i.e. 1e18
         * Hence, one token value in USD = (price * additional feed precision) / precision = (2000 * 1e8 *  1e10 ) / 1e18 = 2000
         */
        uint256 oneTokenValueInUsd =
            (uint256(price) * SV15CConstants.ADDITIONAL_FEED_PRECISION) / SV15CConstants.PRECISION;
        return (oneTokenValueInUsd * amountOfTokens);
    }
}
