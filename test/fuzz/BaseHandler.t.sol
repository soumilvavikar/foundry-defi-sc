//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {SV15C} from "../../../src/SV15Coin.sol";
import {SV15CEngine} from "../../../src/SV15CEngine.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

/**
 * @title BaseHandler
 * @author Soumil Vavikar
 * @notice This contract will setup the BaseHandler which will be used to interact with the SV15C and SV15CEngine contracts
 */
abstract contract BaseHandler is Test {
    SV15C internal sv15c;
    SV15CEngine internal engine;
    MockV3Aggregator public ethUsdPriceFeed;
    MockV3Aggregator public btcUsdPriceFeed;
    ERC20Mock public weth;
    ERC20Mock public wbtc;

    // Ghost Variables
    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    /**
     * The constructor will set the contracts we want this handler to interact with.
     * @param _sv15c - the sv15c contract
     * @param _engine - the engine contract
     */
    constructor(SV15C _sv15c, SV15CEngine _engine) {
        sv15c = _sv15c;
        engine = _engine;

        address[2] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(
            engine.getCollateralTokenPriceFeed(address(weth))
        );
        btcUsdPriceFeed = MockV3Aggregator(
            engine.getCollateralTokenPriceFeed(address(wbtc))
        );
    }

    /**
     * Helper Function to get the collateral token from the seed
     * @notice Get the collateral token from the seed
     * @param collateralSeed - the seed to determine the collateral token
     * @return ERC20Mock - the collateral token
     */
    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) internal view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }

    /**
     * This function will update the price feed with the new price
     * @param newPrice - the new price to update the price feed with
     * @param collateralSeed - the seed to determine the collateral token
     */
    function updateCollateralPrice(
        uint96 newPrice,
        uint256 collateralSeed
    ) public {
        int256 intNewPrice = int256(uint256(newPrice));
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        MockV3Aggregator priceFeed = MockV3Aggregator(
            engine.getCollateralTokenPriceFeed(address(collateral))
        );

        priceFeed.updateAnswer(intNewPrice);
    }

    /**
     * This function will print the call summary
     */
    function callSummary() external view {
        console.log("Weth total deposited", weth.balanceOf(address(engine)));
        console.log("Wbtc total deposited", wbtc.balanceOf(address(engine)));
        console.log("Total supply of DSC", sv15c.totalSupply());
    }
}
