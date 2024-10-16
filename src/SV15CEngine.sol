// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15CEngineInterface} from "./SV15CEngineInterface.sol";
import {SV15C} from "./SV15Coin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SV15CEngine
 * @author Soumil Vavikar
 * The system is designed to be minmalistic, and have 1 coin maintain itself at 1 USD peg.
 * Exogenous, Decentralized, Anchored (pegged)
 *
 * @dev - The SV15C system should always be "OVERCOLLATERALIZED", i.e.
 *        Value of ALL collateral should always be GREATER THAN TOTAL USD BACKED VALUE OF SV15C.
 *
 * Similar to DAI if DAI had no governance, no fees, and was backed only by WETH and WBTC.
 *
 * @notice Core of the SV15C system and contains all the logic (minting, redeeming, depositing and withdrawing collateral).
 * @notice This contract is loosely based on the MakerDAO DSS (DAI) system.
 */
contract SV15CEngine is SV15CEngineInterface, ReentrancyGuard {
    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           ERRORS                                    ////////
    /////////////////////////////////////////////////////////////////////////////////////
    error SV15CEngine__AmountShouldBeMoreThanZero();
    error SV15CEngine__IncorrectTokenAddressToPriceFeedInfo();
    error SV15CEngine__TokenNotAllowed();

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           STATE VARIABLES                           ////////
    /////////////////////////////////////////////////////////////////////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    SV15C private immutable i_sv15c;

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           EVENTS                                    ////////
    /////////////////////////////////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           MODIFIERS                                 ////////
    /////////////////////////////////////////////////////////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert SV15CEngine__AmountShouldBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert SV15CEngine__TokenNotAllowed();
        }
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           CONSTRUCTOR                               ////////
    /////////////////////////////////////////////////////////////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address svcAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert SV15CEngine__IncorrectTokenAddressToPriceFeedInfo();
        }

        // USD Price Feeds. ETH to USD / BTC to USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        // Setting the address of the SV15C contract
        i_sv15c = SV15C(svcAddress);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           EXTERNAL FUNCTIONS                        ////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * This function will accept the collateral and mint the coin accordingly
     *
     * @param tokenCollateralAddress address of the collateral
     * @param amountCollateral amount of collateral
     * @param amountSV15CToMint amount of coin to mint
     */
    function depositCollateralAndMintSV15C(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountSV15CToMint
    ) external override {}

    /**
     * This function will withdraw your collateral and burn SV15C in one transaction
     *
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param amountSV15CToBurn: The amount of coin you want to burn
     */
    function redeemCollateralForSV15C(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountSV15CToBurn
    ) external override {}

    /**
     * This function will redeem your collateral,
     * If you have SV15C minted, you will not be able to redeem until you burn your SV15C
     *
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're redeeming
     * @param amountCollateral: The amount of collateral you're redeeming
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) external override {}

    /**
     * This function will burn the coins. careful! You'll burn your SV15C here! Make sure you want to do this...
     *
     * @param amount amount of the coin to be burnt
     *
     * @dev you might want to use this if you're nervous `you might get liquidated` and want to just burn
     */
    function burnSV15C(uint256 amount) external override {}

    /**
     * This function will liquidate the user. You can partially liquidate a user.
     *
     * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     *                    This is collateral that you're going to take from the user who is insolvent.
     *                    In return, we would burn the coins to pay off their debt, but you don't pay off your own.
     * @param user: The user we want to liquidate.
     * @param debtToCover: The amount of coins to be burnt to cover the debt
     *
     * @dev read more about liquidation and how it works here - https://medium.com/coinmonks/what-is-liquidation-in-defi-lending-and-borrowing-platforms-3326e0ba8d0
     *
     */
    function liquidate(address collateral, address user, uint256 debtToCover) external override {}

    /**
     * This function would tell the health factor of a person.
     *
     * @param totalCoinsMinted: total coins minted
     * @param collateralValueInUsd: total collateral value in USD
     */
    function calculateHealthFactor(uint256 totalCoinsMinted, uint256 collateralValueInUsd) external override {}

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           PUBLIC FUNCTIONS                          ////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * This function will deposit the collateral.
     * @notice Follows CEI - Checks, effects, and interactions
     * 
     * @param tokenCollateralAddress collateral address
     * @param collateralAmount amount collateral
     */
    function depositCollateral(address tokenCollateralAddress, uint256 collateralAmount)
        public
        moreThanZero(collateralAmount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        // Update the collateral deposited mapping for the user
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += collateralAmount;
        // Emit the event.
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, collateralAmount);
    }
    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           PRIVATE FUNCTIONS                         ////////
    /////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           GETTER FUNCTIONS                          ////////
    /////////////////////////////////////////////////////////////////////////////////////
}
