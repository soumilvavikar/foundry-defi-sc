//SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15C} from "../../src/SV15Coin.sol";
import {SV15CEngine} from "../../src/SV15CEngine.sol";
import {console} from "forge-std/console.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";
import {TestConstants} from "../libs/TestConstants.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {SV15CBaseTest} from "./SV15CBaseTest.t.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {MockFailedTransferFrom} from "../mocks/MockFailedTransferFrom.sol";
import {MockFailedMintSV15C} from "../mocks/MockFailedMintSV15C.sol";
import {MockFailedTransfer} from "../mocks/MockFailedTransfer.sol";
import {MockMoreDebtSV15C} from "../mocks/MockMoreDebtSV15C.sol";
import {SV15CConstants} from "../../src/libs/SV15CConstants.sol";

/**
 * @title SV15CEngineTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine contract
 */
contract SV15CEngineTest is SV15CBaseTest {
    /**
     * @notice Test that function reverts if the transfer fails
     */
    function testRevertsIfTransferFromFails() public {
        // Setup the test data
        address owner = msg.sender;
        vm.prank(owner);
        MockFailedTransferFrom mocksv15c = new MockFailedTransferFrom();
        tokenAddresses = [address(mocksv15c)];
        feedAddresses = [ethUsdPriceFeed];

        vm.prank(owner);
        // Deploy the SV15CEngine contract
        SV15CEngine engine = new SV15CEngine(tokenAddresses, feedAddresses, address(mocksv15c));

        // Mint some WETH to the user
        mocksv15c.mint(TestConstants.USER, TestConstants.COLLATERAL_AMOUNT);

        vm.prank(owner);
        // Transfer the ownership of the SV15C contract to the SV15CEngine contract - only the engine can mint and burn tokens
        mocksv15c.transferOwnership(address(engine));

        // Arrange - User
        vm.startPrank(TestConstants.USER);
        ERC20Mock(address(mocksv15c)).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);

        // Act / Assert
        // Expect revert as the transferFrom will fail
        vm.expectRevert(SV15CErrors.SV15CEngine__TokenTranferFailed.selector);
        engine.depositCollateral(address(mocksv15c), TestConstants.COLLATERAL_AMOUNT);

        vm.stopPrank();
    }

    /**
     * @notice Test the depositCollateral function for allowed amount to be more than zero
     */
    function testRevertIfCollateralIsZero() public {
        vm.startPrank(TestConstants.USER);
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    /**
     * @notice Test the depositCollateral function for allowed token address
     */
    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAN", "RAN", TestConstants.USER, 100e18);
        vm.startPrank(TestConstants.USER);
        vm.expectRevert(SV15CErrors.SV15CEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(randToken), TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice Test the depositCollateral function for allowed token address
     */
    function testCanDepositCollateralWithoutMinting() public depositedCollateral {
        uint256 userBalance = sv15c.balanceOf(TestConstants.USER);
        assertEq(userBalance, 0);
        vm.startPrank(TestConstants.USER);
        uint256 ethDeposited = engine.getDepositedCollateral(weth);
        vm.stopPrank();
        assertEq(ethDeposited, TestConstants.COLLATERAL_AMOUNT);
    }

    /**
     * @notice Test the depositCollateral function for allowed token address and get account information
     */
    function testCanDepositCollateralAndGetAcctInfo() public depositedCollateral {
        (uint256 sv15cMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(TestConstants.USER);
        uint256 expectedDepositedAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(sv15cMinted, 0);
        assertEq(expectedDepositedAmount, TestConstants.COLLATERAL_AMOUNT);
    }

    /**
     * @notice Test the depositCollateralAndMintSV15C function reverts when health factor goes down
     */
    function testRevertsIfMintedDscBreaksHealthFactor() public {
        // Getting the number of coins to mint based on the collateral amount (which breaks the health factor)
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        uint256 amountToMint = (
            TestConstants.COLLATERAL_AMOUNT * (uint256(price) * engine.getAdditionalFeedPrecision())
        ) / engine.getPrecision();

        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);

        uint256 expectedHealthFactor =
            engine.calculateHealthFactor(amountToMint, engine.getUsdValueOfToken(weth, TestConstants.COLLATERAL_AMOUNT));

        vm.expectRevert(
            abi.encodeWithSelector(SV15CErrors.SV15CEngine__BreaksHealthFactor.selector, expectedHealthFactor)
        );
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, amountToMint);
        vm.stopPrank();
    }

    /**
     * @notice Test the depositCollateralAndMintSV15C function for allowed token address and mint DSC
     */
    function testCanMintWithDepositedCollateral() public depositedCollateralAndMintedSv15c {
        (uint256 userBalance,) = engine.getAccountInformation(TestConstants.USER);
        assertEq(userBalance, TestConstants.AMOUNT_TO_MINT);
    }

    /**
     *  @notice test that function reverts if the mint fails
     */
    function testRevertsIfMintFails() public {
        // Arrange - Setup - Setting up the mock SV15C instance with failing mint function
        MockFailedMintSV15C mockSv15C = new MockFailedMintSV15C();
        tokenAddresses = [weth, wbtc];
        feedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];
        address owner = msg.sender;

        vm.prank(owner);
        // Deploy the SV15CEngine contract
        SV15CEngine mockEngine = new SV15CEngine(tokenAddresses, feedAddresses, address(mockSv15C));
        // Transfer the ownership of the SV15C contract to the SV15CEngine contract - only the engine can mint and burn tokens
        mockSv15C.transferOwnership(address(mockEngine));

        // Arrange - User
        vm.startPrank(TestConstants.USER);
        // Mint some WETH to the user
        ERC20Mock(weth).approve(address(mockEngine), TestConstants.COLLATERAL_AMOUNT);

        // Act / Assert - Expect revert as the mint will fail
        vm.expectRevert(SV15CErrors.SV15CEngine__MintFailed.selector);
        // Deposit collateral and mint SV15C
        mockEngine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    /**
     * @notice Test the mintSV15C function for allowed amount to be more than zero
     */
    function testRevertsIfMintAmountIsZero() public {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);

        // Act / Assert - Expect revert as the mint amount is zero
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.mintSV15C(0);
        vm.stopPrank();
    }

    /**
     * @notice Test the mintSV15C function for allowed amount to be more than zero
     */
    function testRevertsIfMintAmountBreaksHealthFactor() public depositedCollateral {
        // Getting the number of coins to mint based on the collateral amount (which breaks the health factor)
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        uint256 amountToMint = (
            TestConstants.COLLATERAL_AMOUNT * (uint256(price) * engine.getAdditionalFeedPrecision())
        ) / engine.getPrecision();

        vm.startPrank(TestConstants.USER);
        // Call the calculateHealthFactor function to get the expected health factor
        uint256 expectedHealthFactor =
            engine.calculateHealthFactor(amountToMint, engine.getUsdValueOfToken(weth, TestConstants.COLLATERAL_AMOUNT));
        // Expect revert as the mint amount breaks the health factor
        vm.expectRevert(
            abi.encodeWithSelector(SV15CErrors.SV15CEngine__BreaksHealthFactor.selector, expectedHealthFactor)
        );
        // Mint the SV15C, which will break the health factor
        engine.mintSV15C(amountToMint);
        vm.stopPrank();
    }

    /**
     * @notice Test the mintSV15C function for allowed amount to be more than zero
     */
    function testCanMintSV15C() public depositedCollateral {
        vm.prank(TestConstants.USER);
        // Mint the SV15C
        engine.mintSV15C(TestConstants.AMOUNT_TO_MINT);
        // Get the account information - check if the minting was successful
        (uint256 userBalance,) = engine.getAccountInformation(TestConstants.USER);
        assertEq(userBalance, TestConstants.AMOUNT_TO_MINT);
    }

    /**
     * @notice Test the burnSV15C function for allowed amount to be more than zero
     */
     function testRevertsIfBurnAmountIsZero() public {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);
        // Deposit collateral and mint SV15C
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        //  Act / Assert - Expect revert as the burn amount is zero, which is not allowed
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.burnSV15C(0);
        vm.stopPrank();
    }

    /**
     * @notice Test the burnSV15C function for allowed amount to be more than zero
     */
    function testCantBurnMoreThanUserHas() public {
        vm.prank(TestConstants.USER);
        // Expect revert as the user does not have enough SV15C to burn
        vm.expectRevert();
        engine.burnSV15C(1);
    }

    /**
     * @notice Test the burnSV15C function for allowed amount to be more than zero
     */
    function testCanBurnSV15C() public depositedCollateralAndMintedSv15c {
        vm.startPrank(TestConstants.USER);
        sv15c.approve(address(engine), TestConstants.AMOUNT_TO_MINT);
        // burn the total coins minted by the user
        engine.burnSV15C(TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();

        // Get the account information - check if the burning was successful
        uint256 userBalance = sv15c.balanceOf(TestConstants.USER);
        assertEq(userBalance, 0);
    }

    /**
     * @notice Test the redeemCollateral function for allowed amount to be more than zero
     */
    function testRevertsIfTransferFails() public {
        // Arrange - Setup - Setting up the mock SV15C instance with failing transfer function
        address owner = msg.sender;
        vm.prank(owner);
        MockFailedTransfer mockSv15c = new MockFailedTransfer();
        tokenAddresses = [address(mockSv15c)];
        feedAddresses = [ethUsdPriceFeed];
        vm.prank(owner);
        // Setup the mock SV15CEngine contract
        SV15CEngine mockEngine = new SV15CEngine(tokenAddresses, feedAddresses, address(mockSv15c));
        // Mint some WETH to the user
        mockSv15c.mint(TestConstants.USER, TestConstants.COLLATERAL_AMOUNT);
        vm.prank(owner);
        mockSv15c.transferOwnership(address(mockEngine));

        // Arrange - User
        vm.startPrank(TestConstants.USER);
        ERC20Mock(address(mockSv15c)).approve(address(mockEngine), TestConstants.COLLATERAL_AMOUNT);

        // Act / Assert 
        // Deposit collateral, mint SV15C and then redeem the collateral
        mockEngine.depositCollateral(address(mockSv15c), TestConstants.COLLATERAL_AMOUNT);
        // Expect revert as the transfer will fail
        vm.expectRevert(SV15CErrors.SV15CEngine__TokenTranferFailed.selector);
        // Redeem the collateral
        mockEngine.redeemCollateral(address(mockSv15c), TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice Test the redeemCollateral function for allowed amount to be more than zero
     */
    function testRevertsIfRedeemAmountIsZero() public {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine),  TestConstants.COLLATERAL_AMOUNT);
        // Deposit collateral and mint SV15C
        engine.depositCollateralAndMintSV15C(weth,  TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        // Act / Assert - Expect revert as the redeem amount is zero
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    /**
     * @notice Test the redeemCollateral function for allowed amount to be more than zero
     */
    function testCanRedeemCollateral() public depositedCollateral {
        vm.startPrank(TestConstants.USER);
        // Redeem the collateral
        engine.redeemCollateral(weth,  TestConstants.COLLATERAL_AMOUNT);
        uint256 userBalance = ERC20Mock(weth).balanceOf(TestConstants.USER);
        // Ensure the user balance is the same as the collateral amount
        assertEq(userBalance,  TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice Test the redeemCollateral function for allowed amount to be more than zero
     */
    function testEmitCollateralRedeemedWithCorrectArgs() public depositedCollateral {
        // expect the CollateralRedeemed event to be emitted with the correct arguments
        vm.expectEmit(true, true, true, true, address(engine));
        emit SV15CEngine.CollateralRedeemed(TestConstants.USER, TestConstants.USER, weth,  TestConstants.COLLATERAL_AMOUNT);
        
        vm.startPrank(TestConstants.USER);
        // Redeem the collateral
        engine.redeemCollateral(weth,  TestConstants.COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice Test the redeemCollateralForDsc function for allowed amount to be more than zero
     */
     function testMustRedeemMoreThanZero() public depositedCollateralAndMintedSv15c {
        vm.startPrank(TestConstants.USER);
        sv15c.approve(address(engine), TestConstants.AMOUNT_TO_MINT);
        // Act / Assert - Expect revert as the redeem amount is zero
        vm.expectRevert(SV15CErrors.SV15CEngine__AmountShouldBeMoreThanZero.selector);
        engine.redeemCollateralForSV15C(weth, 0, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    /**
     * @notice Test the redeemCollateralForDsc function for allowed amount to be more than zero
     */
    function testCanRedeemDepositedCollateral() public {
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_AMOUNT);
        // Deposit collateral and mint SV15C
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        sv15c.approve(address(engine), TestConstants.AMOUNT_TO_MINT);
        // Redeem the collateral for SV15C
        engine.redeemCollateralForSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
        // Check the user balance after redeeming the collateral
        uint256 userBalance = sv15c.balanceOf(TestConstants.USER);
        assertEq(userBalance, 0);
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
    function testMustImproveHealthFactorOnLiquidation() public {
        // Arrange - Setup
        MockMoreDebtSV15C mockSv15c = new MockMoreDebtSV15C(ethUsdPriceFeed);
        tokenAddresses = [weth, wbtc];
        feedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];
        address owner = msg.sender;
        
        // Arrange - Engine
        vm.prank(owner);
        SV15CEngine mockEngine = new SV15CEngine(tokenAddresses, feedAddresses, address(mockSv15c));
        mockSv15c.transferOwnership(address(mockEngine));
        // Arrange - User
        vm.startPrank(TestConstants.USER);
        ERC20Mock(weth).approve(address(mockEngine), TestConstants.COLLATERAL_AMOUNT);
        mockEngine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_AMOUNT, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();

        // Arrange - Liquidator
        ERC20Mock(weth).mint(TestConstants.LIQUIDATOR, TestConstants.COLLATERAL_TO_COVER);

        vm.startPrank(TestConstants.LIQUIDATOR);
        ERC20Mock(weth).approve(address(mockEngine), TestConstants.COLLATERAL_TO_COVER);
        
        uint256 debtToCover = 10 ether;
        // Deposit collateral and mint SV15C
        mockEngine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_TO_COVER, TestConstants.AMOUNT_TO_MINT);
        mockSv15c.approve(address(mockEngine), debtToCover);

        // Mock the price feed to crash the health factor
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
        
        // Act/Assert - Expect revert as the health factor does not improve
        vm.expectRevert(SV15CErrors.SV15CEngine__HealthFactorNotImproved.selector);
        mockEngine.liquidate(weth, TestConstants.USER, debtToCover);
        vm.stopPrank();
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
    function testCantLiquidateGoodHealthFactor() public depositedCollateralAndMintedSv15c {
        ERC20Mock(weth).mint(TestConstants.LIQUIDATOR, TestConstants.COLLATERAL_TO_COVER);

        // Arrange - Liquidator
        vm.startPrank(TestConstants.LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), TestConstants.COLLATERAL_TO_COVER);
        // Deposit collateral and mint SV15C
        engine.depositCollateralAndMintSV15C(weth, TestConstants.COLLATERAL_TO_COVER, TestConstants.AMOUNT_TO_MINT);
        sv15c.approve(address(engine), TestConstants.AMOUNT_TO_MINT);

        // Act/Assert - Expect revert as the health factor is good
        vm.expectRevert(SV15CErrors.SV15CEngine__HealthFactorOk.selector);
        engine.liquidate(weth, TestConstants.USER, TestConstants.AMOUNT_TO_MINT);
        vm.stopPrank();
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
     function testLiquidationPayoutIsCorrect() public liquidated {
        // Calculate the amount of WETH to be liquidated
        uint256 liquidatorWethBalance = ERC20Mock(weth).balanceOf(TestConstants.LIQUIDATOR);
        // Calculate the expected WETH amount
        uint256 expectedWeth = engine.getTokenAmountFromUsd(weth, TestConstants.AMOUNT_TO_MINT)
            + (engine.getTokenAmountFromUsd(weth, TestConstants.AMOUNT_TO_MINT) / engine.getLiquidationBonus());

        uint256 hardCodedExpected = 6_111_111_111_111_111_110;
        assertEq(liquidatorWethBalance, hardCodedExpected);
        assertEq(liquidatorWethBalance, expectedWeth);
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
    function testUserStillHasSomeEthAfterLiquidation() public liquidated {
        // Calculate the amount of WETH to be liquidated
        uint256 amountLiquidated = engine.getTokenAmountFromUsd(weth, TestConstants.AMOUNT_TO_MINT)
            + (engine.getTokenAmountFromUsd(weth, TestConstants.AMOUNT_TO_MINT) / engine.getLiquidationBonus());

        // Calculate the amount of USD to be liquid
        uint256 usdAmountLiquidated = engine.getUsdValueOfToken(weth, amountLiquidated);
        //  Calculate the expected user collateral value in USD
        uint256 expectedUserCollateralValueInUsd = engine.getUsdValueOfToken(weth, TestConstants.COLLATERAL_AMOUNT) - (usdAmountLiquidated);
        // Get the account information - check if the user collateral value is correct
        (, uint256 userCollateralValueInUsd) = engine.getAccountInformation(TestConstants.USER);

        uint256 hardCodedExpectedValue = 70_000_000_000_000_000_020;
        assertEq(userCollateralValueInUsd, expectedUserCollateralValueInUsd);
        assertEq(userCollateralValueInUsd, hardCodedExpectedValue);
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
    function testLiquidatorTakesOnUsersDebt() public liquidated {
        (uint256 liquidatorSv15cMinted,) = engine.getAccountInformation(TestConstants.LIQUIDATOR);
        assertEq(liquidatorSv15cMinted, TestConstants.AMOUNT_TO_MINT);
    }

    /**
     * @notice Test the liquidate function for allowed amount to be more than zero
     */
    function testUserHasNoMoreDebt() public liquidated {
        (uint256 userSv15cMinted,) = engine.getAccountInformation(TestConstants.USER);
        assertEq(userSv15cMinted, 0);
    }

    function testPurGetterFunctions() public view {
        assertEq(engine.getLiquidationThreshold(), SV15CConstants.LIQUIDATION_THRESHOLD);
        assertEq(engine.getLiquidationBonus(), SV15CConstants.LIQUIDATION_BONUS);
        assertEq(engine.getLiquidationPrecision(), SV15CConstants.LIQUIDATION_PRECISION);
        assertEq(engine.getMinHealthFactor(), SV15CConstants.MIN_HEALTH_FACTOR);
        assertEq(engine.getAdditionalFeedPrecision(), SV15CConstants.ADDITIONAL_FEED_PRECISION);
    }
}
