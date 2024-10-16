// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {SV15CConstants} from "./SV15CConstants.sol";

/**
 * @title HealthFactorCalculator
 * @author Soumil Vavikar
 * @notice Library for Health Factor Calculator
 */
library HealthFactorCalculator {
    /**
     * This function will calculate the health factor of the user.
     *
     * @param totalSVC15Minted total coins minted by the user
     * @param collateralValueInUsd total collateral value in USD
     */
    function calculateHealthFactor(uint256 totalSVC15Minted, uint256 collateralValueInUsd)
        internal
        pure
        returns (uint256)
    {
        // If coins minted = 0, return health factor as max of uint256 (a positive value)
        if (totalSVC15Minted == 0) {
            return type(uint256).max;
        }

        /**
         * Explaination:
         *  - 1 SV15C = 1 USD
         *  - We always want to be overcollateralized (say 200% -> Hence our liquidation threshold has to be 50)
         *    - i.e. If user has 200 USD as collateral, use can mint ONLY 100 SV15C coins.
         *
         * Calculation below considering - collateral value = 200 USD and coinsMinted = 50
         *  For collateralAdjustedForThreshold
         *  - Collateral valus in USD = 200
         *  - Collateral adjusted for threshold = 200 * 50 = 10,000 >> divided by liquidation precision i.e. 100
         *    >> (200 * 50) / 100 >> 10,000 / 100 = 100
         *
         * NOTE: The minimum health factor has been set to 1e18 (to predefined precision value).
         *
         * Calculations for Health Factor (considering precision): continuing on above example
         *  - (collateral value in USD * 1e18) / totalCoinsMinted
         *    >> (100 * 1e18) / 50 = 2e18
         *    >> 2e18 > 1e18 => Hence Good Health Factor
         *
         *  - Consider if total coins minted were 200
         *    >> (100 * 1e18) / 200 = 0.5e18 OR 5e17
         *    >> 5e17 < 1e18 => Bad Health Factor and the user can be liquidated.
         */
        uint256 collateralAdjustedForThreshold =
            (collateralValueInUsd * SV15CConstants.LIQUIDATION_THRESHOLD) / SV15CConstants.LIQUIDATION_PRECISION;
        // Return the health factor of the user
        return (collateralAdjustedForThreshold * SV15CConstants.PRECISION) / totalSVC15Minted;
    }
}
