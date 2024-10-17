//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {DeploySV15C} from "../../script/DeploySV15C.s.sol";
import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";

/**
 * @title SV15CEngineTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine contract
 */
contract SV15CEngineTest is Test {
    DeploySV15C deploySV15C;
    SV15C sv15c;
    SV15CEngine engine;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;
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
     * @notice Test the getUsdValueOfToken function for WETH
     */
    function testGetUsdValueOfETHToken() public view {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30000e18;
        uint256 wethUsdValue = engine.getUsdValueOfToken(weth, ethAmount);
        console.log("wethUsdValue: ", wethUsdValue);
        console.log("expectedUsd: ", expectedUsd);
        assertEq(wethUsdValue, expectedUsd);
    }

    /**
     * @notice Test the getUsdValueOfToken function for WBTC
     */
    function testGetUsdValueOfBTCToken() public view {
        uint256 btcAmount = 10e18;
        // 10e18 USD * $6000/BTC = $60,000e18
        uint256 expectedUsd = 60000e18;
        uint256 wbtcUsdValue = engine.getUsdValueOfToken(wbtc, btcAmount);
        console.log("wbtcUsdValue: ", wbtcUsdValue);
        console.log("expectedUsd: ", expectedUsd);
        assertEq(wbtcUsdValue, expectedUsd);
    }

    /**
     * @notice Test the depositCollateral function for allowed amount to be more than zero
     */
    function testRevertIfCollateralIsZero() public {
        vm.startPrank(TestConstants.USER);
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

     function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAN", "RAN", TestConstants.USER, 100e18);
        vm.startPrank(TestConstants.USER);
        vm.expectRevert(SV15CErrors.SV15CEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(randToken), TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

}
