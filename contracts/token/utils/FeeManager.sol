// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeManager
 * @dev Contains fee parameters, wallet address storage, and fee calculation.
 *      This abstract contract does NOT enforce access control;
 *      functions that need protection will be implemented in the derived token contract.
 */
abstract contract FeeManager {
    // Wallet addresses for fee distribution.
    address public burnWallet;
    address public utilityWallet;
    address public liquidityWallet;

    // Fee percentages (expressed as whole numbers, where 2 means 2%).
    uint256 public burnFee = 2;        // 2% burn fee
    uint256 public utilityFee = 2;     // 2% utility fee
    uint256 public liquidityFee = 1;   // 1% auto-liquidity fee
    // Total fee = 2 + 2 + 1 = 5%

    // Mapping for addresses exempt from fees.
    mapping(address => bool) public isFeeExempt;

    /**
     * @notice Returns the total fee percentage.
     */
    function totalFee() public view returns (uint256) {
        return burnFee + utilityFee + liquidityFee;
    }
}
