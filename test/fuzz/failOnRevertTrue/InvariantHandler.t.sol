//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {BaseHandler} from "../BaseHandler.t.sol";
import {SV15C} from "../../../src/SV15Coin.sol";
import {SV15CEngine} from "../../../src/SV15CEngine.sol";
import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

/**
 * @title Handler
 * @author Soumil Vavikar
 * @notice This contract is used to interact with the SV15C and SV15CEngine contracts
 */
contract Handler is BaseHandler {
    /**
     * The constructor will set the contracts we want this handler to interact with.
     * @param _sv15c - the sv15c contract
     * @param _engine - the engine contract
     */
    constructor(
        SV15C _sv15c,
        SV15CEngine _engine
    ) BaseHandler(_sv15c, _engine) {}

    /**
     * This function will test the mint and deposit collateral function of the engine
     * @notice Mint and deposit collateral
     * @param collateralSeed - the seed to determine the collateral token
     * @param collateralAmount - the amount of collateral to mint and deposit
     */
    function mintAndDepositCollateral(
        uint256 collateralSeed,
        uint256 collateralAmount
    ) public {
        // Bound the collateral amount to greater than 0 and less than the max deposit size
        collateralAmount = bound(collateralAmount, 1, MAX_DEPOSIT_SIZE);
        // Get the collateral token from the seed
        ERC20Mock collateralToken = _getCollateralFromSeed(collateralSeed);

        vm.startPrank(msg.sender);
        // Mint the collateral token to the user
        collateralToken.mint(msg.sender, collateralAmount);
        // Approve the collateral token to the engine
        collateralToken.approve(address(engine), collateralAmount);
        // Deposit the collateral
        engine.depositCollateral(address(collateralToken), collateralAmount);
        vm.stopPrank();
    }

    /**
     * This function will test the redeemCollateral function of the engine
     * @notice Redeem collateral
     * @param collateralSeed - the seed to determine the collateral token
     * @param collateralAmount - the amount of collateral to redeem
     */
    function redeemCollateral(
        uint256 collateralSeed,
        uint256 collateralAmount
    ) public {
        // Get the collateral token from the seed
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        // Get the max collateral balance of the user
        uint256 maxCollateral = engine.getCollateralBalanceOfUser(
            msg.sender,
            address(collateral)
        );

        // Bound the collateral amount to greater than 0 and less than the max collateral balance
        collateralAmount = bound(collateralAmount, 0, maxCollateral);

        // If the collateral amount is 0, return
        if (collateralAmount == 0) {
            return;
        }
        vm.prank(msg.sender);
        // Redeem the collateral
        engine.redeemCollateral(address(collateral), collateralAmount);
    }

    /**
     * This function will test the burn the sv15c tokens function of the engine
     * @notice Burn SV15C
     * @param amount - the amount of tokens to burn
     */
    function burnTokens(uint256 amount) public {
        // Bound the amount to greater than 0 and less than the user's balance
        amount = bound(amount, 0, sv15c.balanceOf(msg.sender));

        // If the amount is 0, return
        if (amount == 0) {
            return;
        }
        vm.startPrank(msg.sender);
        // Assign the amount of tokens to the engine
        sv15c.approve(address(engine), amount);
        // Burn the tokens
        engine.burnSV15C(amount);
        vm.stopPrank();
    }

    /**
     * This function will test the liquidate function of the engine
     * @notice Liquidate a user
     * @param collateralSeed - the seed to determine the collateral token
     * @param userToBeLiquidated - the user
     * @param debtToCover - the amount of debt to cover
     */
    function liquidate(
        uint256 collateralSeed,
        address userToBeLiquidated,
        uint256 debtToCover
    ) public {
        // Get the min health factor
        uint256 minHealthFactor = engine.getMinHealthFactor();
        // Get the health factor of the user
        uint256 userHealthFactor = engine.getHealthFactor(userToBeLiquidated);

        // If the user's health factor is greater than the min health factor, return
        if (userHealthFactor >= minHealthFactor) {
            return;
        }

        // Bound the debt to cover to greater than 0 and less than the max uint96 value
        debtToCover = bound(debtToCover, 1, uint256(type(uint96).max));
        // Get the collateral token from the seed
        ERC20Mock collateralToken = _getCollateralFromSeed(collateralSeed);
        // Liquidate the user
        engine.liquidate(
            address(collateralToken),
            userToBeLiquidated,
            debtToCover
        );
    }

    /**
     * This function will test the transfer the sv15c tokens function of the engine
     * @notice Transfer SV15C
     * @param to - the address to transfer the tokens to
     * @param amount - the amount of tokens to transfer
     */
    function transferSv15c(address to, uint256 amount) public {
        // If the to address is 0, set it to 1
        if (to == address(0)) {
            to = address(1);
        }
        // Bound the amount to greater than 0 and less than the user's balance
        amount = bound(amount, 0, sv15c.balanceOf(msg.sender));

        // If the amount is 0, return
        if (amount == 0) {
            return;
        }
        vm.startPrank(msg.sender);
        // Transfer the tokens
        sv15c.transfer(to, amount);
        vm.stopPrank();
    }
}
