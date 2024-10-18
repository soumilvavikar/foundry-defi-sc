// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
/**
 * @title SV15CErrors
 * @author Soumil Vavikar
 * @notice Library for SV15C errors
 */

library SV15CErrors {
    
    //////////////////////////////////////////////////////////////////////////////////////
    ////////                           ERRORS                                    ////////
    /////////////////////////////////////////////////////////////////////////////////////
    
    error SV15C__AmountMustBeMoreThanZero();
    error SV15C__BurnAmountExceedsBalance();
    error SV15C__NotZeroAddress();
    
    error SV15CEngine__AmountShouldBeMoreThanZero();
    error SV15CEngine__IncorrectTokenAddressToPriceFeedInfo();
    error SV15CEngine__TokenNotAllowed();
    error SV15CEngine__TokenTranferFailed();
    error SV15CEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error SV15CEngine__HealthFactorOk();
    error SV15CEngine__HealthFactorNotImproved();
    error SV15CEngine__MintFailed();
    error SV15CEngine__BurnFailed();
}
