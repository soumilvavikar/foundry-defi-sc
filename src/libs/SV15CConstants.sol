// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title SV15CConstants
 * @author Soumil Vavikar
 * @notice Constants for the SV15C system
 */
library SV15CConstants {
    // @dev This means you need to be 200% over-collateralized
    uint256 internal constant LIQUIDATION_THRESHOLD = 50;
    // @dev This means you get assets at a 10% discount when liquidating
    uint256 internal constant LIQUIDATION_BONUS = 10;
    // @dev this is the liquidation precision
    uint256 internal constant LIQUIDATION_PRECISION = 100;
    // @dev The minimum health factor a user needs to maintain to be able to complete a transaction like minting or liquidating
    uint256 internal constant MIN_HEALTH_FACTOR = 1e18;
    // @dev the precision used by the contract
    uint256 internal constant PRECISION = 1e18;
    // @dev additional precision required for price feed (as they default to 1e8 for USD values)
    uint256 internal constant ADDITIONAL_FEED_PRECISION = 1e10;
    // @dev the feed precision for the USD Values
    uint256 internal constant FEED_PRECISION = 1e8;
}
