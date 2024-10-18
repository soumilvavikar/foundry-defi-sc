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

/**
 * @title SV15CEngineTest
 * @author Soumil Vavikar
 * @notice Test the SV15CEngine contract
 */
contract SV15CEngineTest is SV15CBaseTest {
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
}
