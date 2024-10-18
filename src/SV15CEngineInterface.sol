// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

/**
 * @title SV15CEngineInterface
 * @author Soumil Vavikar
 * This is an interface for the SV15C system.
 */
interface SV15CEngineInterface {
    /**
     * This function will accept the collateral and mint the coin accordingly
     *
     * @param tokenCollateralAddress address of the collateral
     * @param collateralAmount amount of collateral
     * @param amountSV15CToMint amount of coin to mint
     */
    function depositCollateralAndMintSV15C(
        address tokenCollateralAddress,
        uint256 collateralAmount,
        uint256 amountSV15CToMint
    ) external;

    /**
     * This function will withdraw your collateral and burn SV15C in one transaction
     *
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param collateralAmount: The amount of collateral you're depositing
     * @param amountSV15CToBurn: The amount of coin you want to burn
     */
    function redeemCollateralForSV15C(
        address tokenCollateralAddress,
        uint256 collateralAmount,
        uint256 amountSV15CToBurn
    ) external;

    /**
     * This function will redeem your collateral,
     * If you have SV15C minted, you will not be able to redeem until you burn your SV15C
     *
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're redeeming
     * @param collateralAmount: The amount of collateral you're redeeming
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 collateralAmount) external;

    /**
     * This function will burn the coins. careful! You'll burn your SV15C here! Make sure you want to do this...
     *
     * @param amount amount of the coin to be burnt
     *
     * @dev you might want to use this if you're nervous `you might get liquidated` and want to just burn
     */
    function burnSV15C(uint256 amount) external;

    /**
     * This function will liquidate the user. You can partially liquidate a user.
     *
     * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     *                    This is collateral that you're going to take from the user who is insolvent.
     *                    In return, we would burn the coins to pay off their debt, but you don't pay off your own.
     * @param user: The user we want to liquidate.
     * @param debtToCover: The amount of coins to be burnt to cover the debt
     *
     */
    function liquidate(address collateral, address user, uint256 debtToCover) external;

    /**
     * This function would tell the health factor of a person.
     *
     * @param totalCoinsMinted: total coins minted
     * @param collateralValueInUsd: total collateral value in USD
     */
    function calculateHealthFactor(uint256 totalCoinsMinted, uint256 collateralValueInUsd) external returns (uint256);
}
