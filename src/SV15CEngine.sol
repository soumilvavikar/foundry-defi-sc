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
import {console} from "forge-std/console.sol";

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
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address token, uint256 amount);

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
            console.log("tokenAddresses[i]: ", tokenAddresses[i]);

            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            i_collateralTokens[i] = tokenAddresses[i];

            console.log("s_priceFeeds[tokenAddresses[i]]: ", s_priceFeeds[tokenAddresses[i]]);
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
     *
     * @notice This function will deposit the collateral and mint the coins in one transaction
     */
    function depositCollateralAndMintSV15C(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountSV15CToMint
    ) external override {
        // Deposit the collateral
        depositCollateral(tokenCollateralAddress, amountCollateral);
        // Mint the SV15C coins
        mintSV15C(amountSV15CToMint);
    }

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
    ) external override {
        // Burn the coins first
        burnSV15C(amountSV15CToBurn);
        // Redeem the collateral after burning the coins
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    /**
     * This function will liquidate the user. You can partially liquidate a user.
     *
     * @param collateralTokenAddress: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     *                    This is collateral that you're going to take from the user who is insolvent.
     *                    In return, we would burn the coins to pay off their debt, but you don't pay off your own.
     * @param user: The user we want to liquidate.
     * @param debtToCover: The amount of coins to be burnt to cover the debt
     *
     * @dev read more about liquidation and how it works here
     *  - https://medium.com/coinmonks/what-is-liquidation-in-defi-lending-and-borrowing-platforms-3326e0ba8d0
     *
     * @notice You can partially liquidate the user.
     * @notice Liquidator would get the bonus for liquidating the user.
     * @notice This function working assumes that the protocol will be roughly 150% overcollateralized in order for this
     * to work.
     * @notice A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate
     * anyone.
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
    function liquidate(address collateralTokenAddress, address user, uint256 debtToCover)
        external
        override
        moreThanZero(debtToCover)
        nonReentrant
    {
        /**
         * Initially if collateral deposited (ETH / BTC) is worth 150 USD and 100 SV15C coins are minted, the health factor is 1.5 (considering 1 USD = 1 SV15C coin)
         * But,
         *  - if the value of ETH drops to 100 USD, the health factor would drop to 1.0
         *  - if the value of ETH drops to 50 USD, the health factor would drop to 0.5
         *    - This is when the user is insolvant because at this moment 1 SV15C coin is not backed by 1 USD worth of collateral
         *    - The collateral is taken from the user and the coins are burnt to cover the debt
         * In our coin, the liquidation threshold is 50% (1.5 health factor).
         * Hence, as soon as the value of ETH drops to 100 USD, the user would be liquidated.
         *  - Now, the liquidator has the collateral (100 USD worth ETH) and the user has no debt.
         *  - Here, the user gets a penalty for not maintaining the health factor.
         *
         * Liquidation is the process of selling the collateral to cover the debt.
         */

        // Before liquidating the user, ensure the health factor of the user is less than the minimum health factor.
        uint256 startingHealthFactor = _healthFactor(user);
        if (startingHealthFactor >= SV15CConstants.MIN_HEALTH_FACTOR) {
            // If the health factor of the user is greater than minimum health factor, revert.
            revert SV15CErrors.SV15CEngine__HealthFactorOk();
        }

        // Step 1: Get the total collateral value in USD for the tokens used as collateral by the user
        uint256 tokenAmountToCoverDebt = getTokenAmountFromUsd(collateralTokenAddress, debtToCover);
        // Step 2: Calculate the bonus for the liquidator
        /**
         * Token amount to cover debt = 100 USD
         * Bonus = 10% of the token amount to cover debt
         * Bonus = (100 * 10) / 100 = 10 USD
         * Liquidator would get 110 USD worth of collateral
         */
        uint256 bonusCollateral =
            (tokenAmountToCoverDebt * SV15CConstants.LIQUIDATION_BONUS) / SV15CConstants.LIQUIDATION_PRECISION;
        // Step 3: Total collateral to take from the user
        uint256 totalCollateralToTake = tokenAmountToCoverDebt + bonusCollateral;

        // Step 4: Redeem the collateral from the user
        _redeemCollateral(collateralTokenAddress, totalCollateralToTake, user, msg.sender);
        // Step 5: Burn the coins to cover the debt
        _burnSV15C(debtToCover, user, msg.sender);

        // Step 6: Check the health factor of the user after liquidation
        uint256 endingHealthFactor = _healthFactor(user);
        if (startingHealthFactor <= endingHealthFactor) {
            // If the health factor of the user is greater than minimum health factor, revert.
            revert SV15CErrors.SV15CEngine__HealthFactorNotImproved();
        }

        // Step 7: Check health factor of the liquidator
        _revertIfHealthFactorIsBroken(msg.sender);
    }

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

    /**
     * This function will burn the coins. careful! You'll burn your SV15C here! Make sure you want to do this...
     *
     * @param amount amount of the coin to be burnt
     *
     * @dev you might want to use this if you're nervous `you might get liquidated` and want to just burn
     */
    function burnSV15C(uint256 amount) public override moreThanZero(amount) {
        // Burn the coins
        _burnSV15C(amount, msg.sender, msg.sender);
        // We should revert the process, if the sender burns more coins than the collateral they hold.
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * This function will redeem your collateral,
     * If you have SV15C minted, you will not be able to redeem until you burn your SV15C
     *
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're redeeming
     * @param amountCollateral: The amount of collateral you're redeeming
     *
     * @notice This function will redeem the collateral after checking for the health factor (should be greater than 1 after the collateral is redeemed)
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        override
        moreThanZero(amountCollateral)
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        // We should revert the process, if the sender redeems more collateral than the collateral they hold.
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * This function will return the amount of tokens equivalent to a given amount of USD.
     *
     * @param tokenAddress The address of the token contract (wETH, wBTC)
     * @param usdAmountInWei The amount of USD to get the token amount for
     */
    function getTokenAmountFromUsd(address tokenAddress, uint256 usdAmountInWei) public view returns (uint256) {
        uint256 price = PriceFeeds.getTokenAmountFromUsd(s_priceFeeds[tokenAddress], usdAmountInWei);
        return price;
    }
    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           PRIVATE / INTERNAL FUNCTIONS                         ////////
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * This function will redeem the collateral.
     *
     * @param tokenCollateralAddress The ERC20 token address of the collateral you're redeeming
     * @param amountCollateral The amount of collateral you're redeeming
     * @param fromAddress The address from which the collateral is being redeemed
     * @param toAddress The address to which the collateral is being redeemed
     */
    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address fromAddress,
        address toAddress
    ) private moreThanZero(amountCollateral) {
        // Update the collateral deposited mapping for the user
        s_collateralDeposited[fromAddress][tokenCollateralAddress] -= amountCollateral;
        // Emit the event.
        emit CollateralRedeemed(fromAddress, toAddress, tokenCollateralAddress, amountCollateral);
        // Transfer the collateral from the contract to the sender
        bool success = IERC20(tokenCollateralAddress).transfer(toAddress, amountCollateral);
        // If the transfer fails, revert.
        if (!success) {
            revert SV15CErrors.SV15CEngine__TokenTranferFailed();
        }
    }

    /**
     * This function will burn the coins.
     *
     * @param amount The amount of the coin to be burnt
     *
     * @dev low level function, don't call directly UNTIL the calling function doesn't check the health factor
     */
    function _burnSV15C(uint256 amount, address onBehalfOf, address sv15cProvider) private moreThanZero(amount) {
        // Update the number of coins minted by the user
        s_SVC15Minted[onBehalfOf] -= amount;
        // Transfer the coins from the sender to the contract
        bool success = i_sv15c.transferFrom(sv15cProvider, address(this), amount);
        // If the transfer fails, revert.
        if (!success) {
            revert SV15CErrors.SV15CEngine__BurnFailed();
        }
        // Burn the coins using the SV15C contract's burn function
        i_sv15c.burn(amount);
    }

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
     * This function would tell the health factor of a person.
     *
     * @param totalCoinsMinted: total coins minted
     * @param collateralValueInUsd: total collateral value in USD
     */
    function calculateHealthFactor(uint256 totalCoinsMinted, uint256 collateralValueInUsd)
        public
        pure
        override
        returns (uint256)
    {
        return HealthFactorCalculator.calculateHealthFactor(totalCoinsMinted, collateralValueInUsd);
    }

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
    function getHealthFactor(address userAddress) public view returns (uint256) {
        return _healthFactor(userAddress);
    }

    /**
     * This function will return the amount of tokens equivalent to a given amount of USD.
     * @param tokenAddress The address of the token contract
     */
    function getDepositedCollateral(address tokenAddress) public view returns (uint256) {
        return s_collateralDeposited[msg.sender][tokenAddress];
    }

    /**
     * This function will return the total coins minted by the user.
     *
     * @param userAddress user address we want to check health factor for
     * @return totalSVC15Minted the total SVC15 minted by the user
     * @return collateralValueInUsd the total collateral value in USD for the user
     */
    function getAccountInformation(address userAddress)
        public
        view
        returns (uint256 totalSVC15Minted, uint256 collateralValueInUsd)
    {
        return _getAccountInformation(userAddress);
    }

    /**
     * Thie function will return the additional feed precision.
     */
    function getAdditionalFeedPrecision() public pure returns (uint256) {
        return SV15CConstants.ADDITIONAL_FEED_PRECISION;
    }

    /**
     * This function will return the precision.
     */
    function getPrecision() public pure returns (uint256) {
        return SV15CConstants.PRECISION;
    }
}
