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
 * @title SV15CConstructorTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine's SV15CConstructorTest
 */
contract SV15CConstructorTest is SV15CBaseTest {
    /**
     * @notice Test if the constructor reverts if the token length is less than the price feeds length
     */
    function testRevertsIfTokenLengthLessThanPriceFeedsLength() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(SV15CErrors.SV15CEngine__IncorrectTokenAddressToPriceFeedInfo.selector);
        new SV15CEngine(tokenAddresses, feedAddresses, address(sv15c));
    }

    /**
     * @notice Test if the constructor reverts if the token length is more than the price feeds length
     */
    function testRevertsIfTokenLengthMoreThanPriceFeedsLength() public {
        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);
        feedAddresses.push(ethUsdPriceFeed);

        vm.expectRevert(SV15CErrors.SV15CEngine__IncorrectTokenAddressToPriceFeedInfo.selector);
        new SV15CEngine(tokenAddresses, feedAddresses, address(sv15c));
    }
}
