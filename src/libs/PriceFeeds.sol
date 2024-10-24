// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {SV15CConstants} from "./SV15CConstants.sol";
import {console} from "forge-std/console.sol";
import {AggregatorV3Lib, AggregatorV3Interface} from "../../src/libs/AggregatorV3Lib.sol";

/**
 * @title PriceFeeds
 * @author Soumil Vavikar
 * @notice Library for price feeds
 */
library PriceFeeds {
    /**
     * Type declarations
     */
    using AggregatorV3Lib for AggregatorV3Interface;

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
        int256 price = getLatestPrice(priceFeedAddress);
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

    function getTokenAmountFromUsd(address priceFeedAddress, uint256 usdAmountInWei) public view returns (uint256) {
        int256 price = getLatestPrice(priceFeedAddress);
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
         * Hence, token amount FROM USD = (usdAmountinWei * precision) / (price of 1 ETH * additional feed precision)
         *  = (usdAmountInWei * 1e18) / (2000e8 * 1e10)
         */
        return
            ((usdAmountInWei * SV15CConstants.PRECISION) / (uint256(price) * SV15CConstants.ADDITIONAL_FEED_PRECISION));
    }

    /**
     * This function will get the latest USD value of the token from the chainlink price feed.
     *
     * @param priceFeedAddress the address of the price feed
     */
    function getLatestPrice(address priceFeedAddress) private view returns (int256 price) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, price,,,) = priceFeed.staleCheckLatestRoundData();
        return price;
    }
}
