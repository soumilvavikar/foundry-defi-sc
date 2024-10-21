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
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

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

    /**
     * @notice Modifier to liquidate a user
     */
    modifier liquidated() {
        // Deposit collateral and mint sv15c
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18

        // Crashing the price
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
        uint256 userHealthFactor = engine.getHealthFactor(TestConstants.USER);

        // Mint some WETH to the liquidator
        ERC20Mock(weth).mint(TestConstants.LIQUIDATOR, TestConstants.COLLATERAL_TO_COVER);

        // Liquidate the user
        vm.startPrank(TestConstants.LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_TO_COVER);
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_TO_COVER, TestConstants.AMOUNT_TO_MINT);
        sv15c.approve(address(engine), TestConstants.AMOUNT_TO_MINT);
        // We are covering their whole debt
        engine.liquidate(weth, TestConstants.USER, TestConstants.AMOUNT_TO_MINT); 
        vm.stopPrank();
        _;
    }
}
