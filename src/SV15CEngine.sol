// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15CEngineInterface} from "./SV15CEngineInterface.sol";
import {SV15C} from "./SV15Coin.sol";
import {SV15CErrors} from "./libs/SV15CErrors.sol";
import {SV15CConstants} from "./libs/SV15CConstants.sol";
import {PriceFeeds} from "./libs/PriceFeeds.sol";
import {HealthFactorCalculator} from "./libs/HealthFactorCalculator.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

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
    ////////                           STATE VARIABLES                           ////////
    /////////////////////////////////////////////////////////////////////////////////////

    SV15C private immutable i_sv15c;

    // @dev mapping between the token (ETH/BTC) to the Chainlink pricefeeds
    mapping(address token => address priceFeed) private s_priceFeeds;
    // @dev mapping for the collateral deposisted by a user
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    // @dev mapping for storing coins minted by the user.
    mapping(address user => uint256 amountOfCoinsMinted) private s_SVC15Minted;
    // @dev - if we have the final list of tokens this stablecoin will support, we can make it immutable OR we can make it a private state variable.
    address[2] private i_collateralTokens;

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           EVENTS                                    ////////
    /////////////////////////////////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           MODIFIERS                                 ////////
    /////////////////////////////////////////////////////////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert SV15CErrors.SV15CEngine__TokenNotAllowed();
        }
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           CONSTRUCTOR                               ////////
    /////////////////////////////////////////////////////////////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address svcAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert SV15CErrors.SV15CEngine__IncorrectTokenAddressToPriceFeedInfo();
        }

        // USD Price Feeds. ETH to USD / BTC to USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            i_collateralTokens[i] = tokenAddresses[i];
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
        // Transfer the collateral from the sender to the contract
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        // If the transfer fails, revert.
        if (!success) {
            revert SV15CErrors.SV15CEngine__TokenTranferFailed();
        }
    }

    /**
     * This function will mint the SV15C tokens.
     *
     *
     * @param amountToMint The amount of SV15C coins to be minted
     *
     * @dev This function also follows CEI
     * @notice the minter should have more collateral value than the amount of coins they mint.
     */
    function mintSV15C(uint256 amountToMint) public moreThanZero(amountToMint) nonReentrant {
        // Update the number of coins minted by the user
        s_SVC15Minted[msg.sender] += amountToMint;
        // We should revert the process, if the sender mints more coins than the collateral they hold.
        _revertIfHealthFactorIsBroken(msg.sender);
        // Once the heath factor is checked, mint the SV15C coins
        bool minted = i_sv15c.mint(msg.sender, amountToMint);
        if (minted != true) {
            revert SV15CErrors.SV15CEngine__MintFailed();
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           PRIVATE / INTERNAL FUNCTIONS                         ////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * This function will revert the transaction if the health factor is broken.
     *
     * @param userAddress user address we want to check health factor for
     */
    function _revertIfHealthFactorIsBroken(address userAddress) internal view {
        // Get the health factor of the user
        uint256 userHealthFactor = _healthFactor(userAddress);
        // If the health factor is below the minimum allowed health factor, revert.
        if (userHealthFactor < SV15CConstants.MIN_HEALTH_FACTOR) {
            revert SV15CErrors.SV15CEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    /**
     * This function will calculate the health factor of the user.
     *
     * @param userAddress user address we want to check health factor for
     */
    function _healthFactor(address userAddress) private view returns (uint256) {
        // Get the total coins minted and total collateral value in USD for the user
        (uint256 totalSVC15Minted, uint256 collateralValueInUsd) = _getAccountInformation(userAddress);
        // Use the total coins minted and total collateral value in USD to determine the health factor of the user.
        return HealthFactorCalculator.calculateHealthFactor(totalSVC15Minted, collateralValueInUsd);
    }

    /**
     * This function will return the total coins minted and total collateral value in USD for the user.
     *
     * @param userAddress user address we want to check health factor for
     */
    function _getAccountInformation(address userAddress)
        private
        view
        returns (uint256 totalSVC15Minted, uint256 collateralValueInUsd)
    {
        // Get the total coins minted from the state variable
        totalSVC15Minted = s_SVC15Minted[userAddress];
        // Get the total collateral value in USD for the tokens used as collateral by the user
        collateralValueInUsd = _getAccountCollateralValueInUsd(userAddress);
        // The return statement is optional (as returns has the variables defined)
        return (totalSVC15Minted, collateralValueInUsd);
    }

    /**
     * This function will return the total collateral value in USD for the user.
     *
     * @param userAddress user address we want to check health factor for
     */
    function _getAccountCollateralValueInUsd(address userAddress)
        internal
        view
        returns (uint256 totalCollateralValueInUsd)
    {
        // Iterate through array of possible tokens and find the total value in USD for all tokens combined.
        for (uint256 i = 0; i < i_collateralTokens.length; i++) {
            address tokenAddress = i_collateralTokens[i];
            uint256 amountOfTokens = s_collateralDeposited[userAddress][tokenAddress];
            totalCollateralValueInUsd += PriceFeeds.getUsdValueOfToken(s_priceFeeds[tokenAddress], amountOfTokens);
        }
        // The return statement is optional (as returns has the variable defined)
        return totalCollateralValueInUsd;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ////////                      PUBLIC VIEW / PURE FUNCTIONS                   ////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * This function will return the total collateral value in USD for the user.
     *
     * @param userAddress user address we want to check health factor for
     */
    function getAccountCollateralValueInUsd(address userAddress)
        public
        view
        returns (uint256 totalCollateralValueInUsd)
    {
        return _getAccountCollateralValueInUsd(userAddress);
    }

    /**
     * This function returns the USD value of a given amount of tokens.
     *
     * @param tokenAddress The address of the token contract
     * @param amountOfTokens The amount of tokens to get the USD value for
     */
    function getUsdValueOfToken(address tokenAddress, uint256 amountOfTokens)
        public
        view
        returns (uint256 usdValueOfToken)
    {
        return PriceFeeds.getUsdValueOfToken(s_priceFeeds[tokenAddress], amountOfTokens);
    }

    /**
     * This function would tell the health factor of the user.
     * @param userAddress user address we want to check health factor for
     */
    function healthFactor(address userAddress) public view returns (uint256) {
        return _healthFactor(userAddress);
    }
}
