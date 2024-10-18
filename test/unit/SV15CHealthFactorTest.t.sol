//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {console} from "forge-std/console.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {SV15CBaseTest} from "./SV15CBaseTest.t.sol";

/**
 * @title SV15CHealthFactorTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine's health factor functions
 */
contract SV15CHealthFactorTest is SV15CBaseTest {
    /**
     *  @notice Test the health factor calculation
     */
    function testProperlyReportsHealthFactor() public depositedCollateralAndMintedSv15c {
        uint256 expectedHealthFactor = 100 ether;
        uint256 healthFactor = engine.getHealthFactor(TestConstants.USER);
        // $100 minted with $20,000 collateral at 50% liquidation threshold
        // means that we must have $200 collatareral at all times.
        // 20,000 * 0.5 = 10,000
        // 10,000 / 100 = 100 health factor
        assertEq(healthFactor, expectedHealthFactor);
    }

    /**
     *  @notice Test the health factor can go below 1
     */
    function testHealthFactorCanGoBelowOne() public depositedCollateralAndMintedSv15c {
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
        // Rememeber, we need $200 at all times if we have $100 of debt

        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);

        uint256 healthFactor = engine.getHealthFactor(TestConstants.USER);
        // 180*50 (LIQUIDATION_THRESHOLD) / 100 (LIQUIDATION_PRECISION) / 100 (PRECISION) = 90 / 100 (totalDscMinted) =
        // 0.9
        assert(healthFactor == 0.9 ether);
    }
}
