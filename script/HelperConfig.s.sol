// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {TestConstants} from "test/libs/TestConstants.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    NetworkConfig public activeConfig;

    constructor() {
        // Sepolia chainid - 11155111 - https://sepolia.etherscan.io/
        if (block.chainid == 11155111) {
            activeConfig = getSepoliaEthConfig();
        } else {
            activeConfig = getOrCreateAnvilEthConfig();
        }
    }

    /**
     * @notice Get the configuration for Sepolia chain
     * @return NetworkConfig
     */
    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            // Sepolia ETH price feed address from Chainlink - https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            // Sepolia WBTC price feed address from Chainlink - https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            // Sepolia WETH address - https://sepolia.etherscan.io/address/0xdd13E55209Fd76AfE204dBda4007C227904f0a81
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            // Sepolia WBTC address - https://sepolia.etherscan.io/address/0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            // Sepolia deployer key
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    /**
     * @notice Get the configuration for Anvil chain
     * @return NetworkConfig
     */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeConfig.wethUsdPriceFeed != address(0)) {
            return activeConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator wethUsdPriceFeed = new MockV3Aggregator(TestConstants.DECIMALS, TestConstants.ETH_USD_PRICE);
        ERC20Mock weth = new ERC20Mock();
        MockV3Aggregator wbtcUsdPriceFeed = new MockV3Aggregator(TestConstants.DECIMALS, TestConstants.BTC_USD_PRICE);
        ERC20Mock wbtc = new ERC20Mock();

        vm.stopBroadcast();

        activeConfig = NetworkConfig({
            wethUsdPriceFeed: address(wethUsdPriceFeed),
            wbtcUsdPriceFeed: address(wbtcUsdPriceFeed),
            weth: address(weth),
            wbtc: address(wbtc),
            // Anvil deployer key
            deployerKey: TestConstants.DEFAULT_ANVIL_PRIVATE_KEY
        });

        return activeConfig;
    }
}
