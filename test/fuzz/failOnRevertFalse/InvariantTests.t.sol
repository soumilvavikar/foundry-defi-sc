//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {InvariantBaseTest} from "../InvariantBaseTest.t.sol";
import {Handler} from "./InvariantHandler.t.sol";
import {DeploySV15C} from "../../../script/DeploySV15C.s.sol";
import {SV15C} from "../../../src/SV15Coin.sol";
import {SV15CEngine} from "../../../src/SV15CEngine.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {SV15CErrors} from "../../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../../libs/TestConstants.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

/**
 * @title InvariantTests
 * @author Soumil Vavikar
 * @notice Invariant Testing - failOnRevertFalse
 */
contract InvariantTests is InvariantBaseTest {
    Handler public handler;

    /**
     * @notice Setup the test
     */
    function setUp() public override {
        // Setup the SV15C and SV15CEngine contracts
        super.setUp();
        // Create the handler
        handler = new Handler(sv15c, engine);
        // Set the handler as the target contract
        targetContract(address(handler));
    }

    /**
     * @notice The protocol must have more value than the total supply of SV15C
     */
    /// forge-config: default.invariant.fail-on-revert = false
    function invariant_failOnRevertFalse_protocolMustHaveMoreValueThatTotalSupplyDollars()
        public
        view
    {
        uint256 totalSupply = sv15c.totalSupply();
        uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(engine));
        uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getUsdValueOfToken(weth, wethDeposted);
        uint256 wbtcValue = engine.getUsdValueOfToken(wbtc, wbtcDeposited);

        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);

        assert(wethValue + wbtcValue >= totalSupply);
    }

    /**
     * This function will call the summary function of the handler
     */
    /// forge-config: default.invariant.fail-on-revert = false
    function invariant_failOnRevertFalse_callSummary() public view {
        handler.callSummary();
    }
}
