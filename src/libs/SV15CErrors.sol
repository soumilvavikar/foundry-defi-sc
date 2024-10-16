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
    
    error SV15CEngine__AmountShouldBeMoreThanZero();
    error SV15CEngine__IncorrectTokenAddressToPriceFeedInfo();
    error SV15CEngine__TokenNotAllowed();
    error SV15CEngine__TokenTranferFailed();
    error SV15CEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error SV15CEngine__MintFailed();
}
