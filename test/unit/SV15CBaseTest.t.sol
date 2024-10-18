//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {DeploySV15C} from "../../script/DeploySV15C.s.sol";
import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

/**
 * @title SV15CBaseTest
 * @author Soumil Vavikar
 * @notice Base test for SV15C
 */
abstract contract SV15CBaseTest is Test {
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
    function setUp() public {
        // Deploy the SV15C and SV15CEngine contracts
        deploySV15C = new DeploySV15C();
        (sv15c, engine, helperConfig) = deploySV15C.run();

        // Get the active network configuration
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeConfig();

        // Mint some WETH and WBTC to the user
        ERC20Mock(weth).mint(TestConstants.USER, TestConstants.STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(TestConstants.USER, TestConstants.STARTING_USER_BALANCE);
    }

    /**
     * @notice Modifier to deposit collateral and mint sv15c
     */
    modifier depositedCollateralAndMintedSv15c() {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
        _;
    }

    /**
     * @notice Modifier to deposit collateral
     */
    modifier depositedCollateral() {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);
        engine.depositCollateral(weth, TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
        _;
    }
}
