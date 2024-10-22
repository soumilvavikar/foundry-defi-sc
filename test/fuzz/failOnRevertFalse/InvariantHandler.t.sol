//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {BaseHandler} from "../BaseHandler.t.sol";
import {SV15C} from "../../../src/SV15Coin.sol";
import {SV15CEngine} from "../../../src/SV15CEngine.sol";
import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

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
     * @param amountCollateral - the amount of collateral to mint and deposit
     */
    function mintAndDepositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        collateral.mint(msg.sender, amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
    }

    /**
     * This function will test the redeemCollateral function of the engine
     * @notice Redeem collateral
     * @param collateralSeed - the seed to determine the collateral token
     * @param amountCollateral - the amount of collateral to redeem
     */
    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        engine.redeemCollateral(address(collateral), amountCollateral);
    }

    /**
     * This function will test the mintDsc function of the sv15c contract
     * @notice Burn SV15C
     * @param amount - the amount of SV15C to mint
     */
    function burn(uint256 amount) public {
        amount = bound(amount, 0, sv15c.balanceOf(msg.sender));
        sv15c.burn(amount);
    }

    /**
     * This function will test the mintDsc function of the sv15c contract
     * @notice Mint SV15C
     * @param amount - the amount of SV15C to mint
     */
    function mint(uint256 amount) public {
        amount = bound(amount, 0, MAX_DEPOSIT_SIZE);
        sv15c.mint(msg.sender, amount);
    }

    /**
     * This function will test the liquidate function of the engine
     * @param collateralSeed - the seed to determine the collateral token
     * @param userToBeLiquidated - the user to be liquidated
     * @param debtToCover - the amount of debt to cover
     */
    function liquidate(
        uint256 collateralSeed,
        address userToBeLiquidated,
        uint256 debtToCover
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        engine.liquidate(address(collateral), userToBeLiquidated, debtToCover);
    }

    /**
     * This function will test the transfer function of the sv15c contract
     * @notice Transfer SV15C
     * @param amount - the amount of SV15C to transfer
     * @param to - the address to transfer the SV15C to
     */
    function transfer(uint256 amount, address to) public {
        amount = bound(amount, 0, sv15c.balanceOf(msg.sender));
        vm.prank(msg.sender);
        sv15c.transfer(to, amount);
    }
}
