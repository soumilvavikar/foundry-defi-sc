// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title TestConstants
 * @author Soumil Vavikar
 * @notice Constants for testing purposes only
 */
library TestConstants {

    address public constant USER = address(0x1);

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 6000e8;
    string public constant WETH = "WETH";
    string public constant WBTC = "WBTC";
    // Anvil deployer key for testing
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 public constant COLLATERAL_AMOUNT = 100 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
}