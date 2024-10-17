// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title TestConstants
 * @author Soumil Vavikar
 * @notice Constants for testing purposes only
 */
library TestConstants {
    uint8 internal constant DECIMALS = 8;
    int256 internal constant ETH_USD_PRICE = 2000e8;
    int256 internal constant BTC_USD_PRICE = 6000e8;
    string internal constant WETH = "WETH";
    string internal constant WBTC = "WBTC";
    // Anvil deployer key for testing
    uint256 internal constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
}