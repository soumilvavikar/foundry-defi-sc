//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {console} from "forge-std/console.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {SV15CBaseTest} from "./SV15CBaseTest.t.sol";

/**
 * @title SVC15PriceFeedTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine's price feed functions
 */
contract SV15CPriceFeedTest is SV15CBaseTest {
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
     * @notice Test the getETHTokenValueFromUsd function
     */
    function testGetETHTokenValueFromUsd() public view {
        uint256 usdAmount = 30000e18;
        // $30,000e18 / $2000/ETH = 15e18
        uint256 expectedEth = 15e18;
        uint256 ethAmount = engine.getTokenAmountFromUsd(weth, usdAmount);
        console.log("ethAmount: ", ethAmount);
        console.log("expectedEth: ", expectedEth);
        assertEq(ethAmount, expectedEth);
    }

    /**
     * @notice Test the getBTCTokenValueFromUsd function
     */
    function testGetBTCTokenValueFromUsd() public view {
        uint256 usdAmount = 60000e18;
        // $60,000e18 / $6000/BTC = 10e18
        uint256 expectedBtc = 10e18;
        uint256 btcAmount = engine.getTokenAmountFromUsd(wbtc, usdAmount);
        console.log("btcAmount: ", btcAmount);
        console.log("expectedBtc: ", expectedBtc);
        assertEq(btcAmount, expectedBtc);
    }
}
