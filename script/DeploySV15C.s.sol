// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {SV15CEngine} from "src/SV15CEngine.sol";
import {SV15C} from "src/SV15Coin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

/**
 * @title DeploySV15C
 * @author Soumil Vavikar
 * @notice This is the deployer contract to deploy the SV15C stablecoin contract.
 */
contract DeploySV15C is Script {
    address[] private tokenAddresses;
    address[] private priceFeedAddresses;

    function run() external returns (SV15C, SV15CEngine, HelperConfig) {
        // Get the active configuration
        HelperConfig helperConfig = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeConfig();

        // Token addresses
        tokenAddresses = [weth, wbtc];
        // Price feed addresses
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        // Start the broadcast - using the deployer key.
        vm.startBroadcast(deployerKey);
        // Deploy the SV15C contract
        SV15C sv15c = new SV15C();
        // Deploy the SV15CEngine contract
        SV15CEngine engine = new SV15CEngine(tokenAddresses, priceFeedAddresses, address(sv15c));
        // Transfer the ownership of the SV15C contract to the SV15CEngine contract - only the engine can mint and burn tokens
        sv15c.transferOwnership(address(engine));
        // Stop the broadcast as the deployment is complete
        vm.stopBroadcast();

        return (sv15c, engine, helperConfig);
    }
}
