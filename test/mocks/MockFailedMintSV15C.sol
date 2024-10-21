// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {SV15CErrors} from "../../src/libs/SV15CErrors.sol";

/**
 * @title MockFailedMintSV15C
 * @author Soumil Vavikar
 * @notice Mock contract to simulate a failed mint 
 */
contract MockFailedMintSV15C is ERC20Burnable, Ownable {

    /*
    In newer versions of OpenZeppelin contracts package, Ownable must be declared with an address of the contract owner
    as a parameter.
    For example:
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) {}
    Related code changes can be viewed in this commit:
    https://github.com/OpenZeppelin/openzeppelin-contracts/commit/13d5e0466a9855e9305119ed383e54fc913fdc60
    */
    constructor() ERC20("SV15C", "DSV15") Ownable(msg.sender) { }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert SV15CErrors.SV15C__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert SV15CErrors.SV15C__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert SV15CErrors.SV15C__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert SV15CErrors.SV15C__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        
        // Returning false to simulate a failed mint
        return false;
    }
}