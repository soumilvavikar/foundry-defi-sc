//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test, StdInvariant} from "forge-std/Test.sol";
import {DeploySV15C} from "../../script/DeploySV15C.s.sol";
import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

abstract contract InvariantBaseTest is StdInvariant, Test {
    DeploySV15C deploySV15C;
    SV15C internal sv15c;
    SV15CEngine internal engine;
    HelperConfig internal helperConfig;

    address internal ethUsdPriceFeed;
    address internal btcUsdPriceFeed;
    address internal weth;
    address internal wbtc;
    uint256 internal deployerKey;

    address[] internal tokenAddresses;
    address[] internal feedAddresses;

    /**
     * @notice Setup the test
     */
    function setUp() virtual public {
        // Deploy the SV15C and SV15CEngine contracts
        deploySV15C = new DeploySV15C();
        (sv15c, engine, helperConfig) = deploySV15C.run();

        // Get the active network configuration
        (
            ethUsdPriceFeed,
            btcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey
        ) = helperConfig.activeConfig();
    }
}
