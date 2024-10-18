// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// Ownable ensures that the stablecoin contract is owned by a single entity and that entity has the ability to mint and burn tokens.
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SV15CErrors} from "./libs/SV15CErrors.sol";

/**
 * @title SV15C
 * @author Soumil Vavikar
 * @notice This contract is a simple decentralized cryptocurrency contract.
 * Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin. ERC20 token that can be minted and burned
 * Check README.md for more details.
 */
contract SV15C is ERC20Burnable, Ownable {

    /**
     * SV15C constructor
     */
    constructor() ERC20("SV15C", "DSV15") Ownable(msg.sender) {}

    /**
     * @notice Mint new tokens
     * @param _to The address to which the tokens will be minted
     * @param _amount The amount of tokens to mint
     * @return bool value
     */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        _mint(_to, _amount);

        if (_to == address(0)) {
            revert SV15CErrors.SV15C__NotZeroAddress();
        }

        // If the amount is less than zero, don't mint, throw an error
        if (_amount <= 0) {
            revert SV15CErrors.SV15C__AmountMustBeMoreThanZero();
        }

        _mint(_to, _amount);

        return true;
    }

    /**
     * @notice Burn tokens
     * @param _amount The amount of tokens to burn
     */
    function burn(uint256 _amount) public override onlyOwner {
        // Current balance of the message sender.
        uint256 balance = balanceOf(msg.sender);

        // If the amount is less than zero, don't burn, throw an error
        if (_amount <= 0) {
            revert SV15CErrors.SV15C__AmountMustBeMoreThanZero();
        }

        // If the amount is more than the balance the sender has, throw an error
        if (_amount > balance) {
            revert SV15CErrors.SV15C__BurnAmountExceedsBalance();
        }

        // All the checks have passed, now we can burn the _amount
        super.burn(_amount);
    }
}
