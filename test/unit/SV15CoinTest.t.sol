// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {SV15C} from "src/SV15Coin.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title SV15CoinTest
 * @notice Test the SV15Coin contract
 */
contract SV15CoinTest is Test {
    SV15C sv15c;

    function setUp() public {
        sv15c = new SV15C();
    }

    /**
     * @notice Test the mint function for allowed amount to be more than zero
     */
    function testMustMintMoreThanZero() public {
        vm.prank(sv15c.owner());
        vm.expectRevert();
        sv15c.mint(address(this), 0);
    }

    /**
     * @notice Test the burn function for allowed amount to be more than zero
     */
    function testMustBurnMoreThanZero() public {
        vm.startPrank(sv15c.owner());
        sv15c.mint(address(this), 100);
        vm.expectRevert();
        sv15c.burn(0);
        vm.stopPrank();
    }

    /**
     * @notice Test the burn function for allowed amount to be less than or equal to the balance
     */
    function testCantBurnMoreThanYouHave() public {
        vm.startPrank(sv15c.owner());
        sv15c.mint(address(this), 30);
        vm.expectRevert();
        sv15c.burn(101);
        vm.stopPrank();
    }

    /**
     * @notice Test the mint function for allowed amount to be less than or equal to the balance
     */
    function testCantMintToZeroAddress() public {
        vm.startPrank(sv15c.owner());
        vm.expectRevert();
        sv15c.mint(address(0), 100);
        vm.stopPrank();
    }

    /**
     * @notice Test the burn function for allowed amount to be less than or equal to the balance
     */
    function testCantBurnLessThanYouHave() public {
        vm.startPrank(sv15c.owner());
        sv15c.mint(address(this), 100);
        sv15c.burn(1);
        vm.stopPrank();
    }

    /**
     * @notice Only owner can mint
     */
    function testOnlyOwnerCanMint() public {
        vm.startPrank(address(0));
        vm.expectRevert();
        sv15c.mint(address(this), 100);
        vm.stopPrank();
    }

    /**
     * @notice Only owner can burn
     */
    function testOnlyOwnerCanBurn() public {
        vm.startPrank(address(0));
        vm.expectRevert();
        sv15c.burn(100);
        vm.stopPrank();
    }
}
