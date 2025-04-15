// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "contracts/token/utils/FeeManager.sol";

/**
 * @title CrocodiloBomberdino
 * @dev Upgradeable ERC20 token with a 5% fee on transfers:
 *      2% burn, 2% utility, and 1% liquidity.
 *      Uses the UUPS upgradeable pattern and integrates fee management.
 */
contract CrocodiloBomberdino is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, FeeManager {
    // Total supply: 1 Billion tokens (with 18 decimals)
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;

    /**
     * @dev Initializes the contract: sets token details, mints the total supply,
     *      initializes fee wallet addresses (replace these with your secure addresses before mainnet deployment),
     *      and exempts the deployer and the contract itself from fees.
     */
    function initialize() public initializer {
        __ERC20_init("Crocodilo Bomberdino", "BOMBERDINO");
        __Ownable_init(msg.sender); // Initialize the contract with msg.sender as owner. // OwnableUpgradeable initializes owner as msg.sender internally.
        __UUPSUpgradeable_init();

        // Mint the full supply to the deployer (owner)
        _mint(msg.sender, INITIAL_SUPPLY);

        // Set initial fee wallet addresses (replace with secure addresses before mainnet deployment)
        burnWallet = 0x077da53e0865f111B35912d400822bA89401Ca64;
        utilityWallet = 0x775AFE34497a187350607d669c097DD9F6DDfaad;
        liquidityWallet = 0xd42509a701A192ce204E5FB1be4fBa0C8b08a982;

        // Exempt the deployer (owner) and the contract itself from fees.
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
    }

    /**
     * @dev UUPS upgrade authorization function. Only the owner can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Overrides the ERC20 _transfer function to apply a 5% fee on transfers.
     *      The fee is split as follows:
     *        - 2% is sent to the burn wallet.
     *        - 2% is sent to the utility wallet.
     *        - 1% is sent to the liquidity wallet.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            // If either sender or recipient is fee-exempt, transfer full amount.
            super._transfer(sender, recipient, amount);
        } else {
            // Calculate fee amounts.
            uint256 feeTotal = (amount * totalFee()) / 100;
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 utilityAmount = (amount * utilityFee) / 100;
            uint256 liquidityAmount = feeTotal - burnAmount - utilityAmount;

            // Transfer fees to respective wallets.
            super._transfer(sender, burnWallet, burnAmount);
            super._transfer(sender, utilityWallet, utilityAmount);
            super._transfer(sender, liquidityWallet, liquidityAmount);

            // Transfer the net amount to the recipient.
            super._transfer(sender, recipient, amount - feeTotal);
        }
    }

    // -----------------------------------------------------------
    // Owner-Protected Functions for Updating Fee Parameters and Wallets
    // -----------------------------------------------------------

    /**
     * @notice Updates the fee exemption status for an account.
     * @param account The address to update.
     * @param exempt  Boolean flag indicating if the account should be fee-exempt.
     */
    function updateFeeExemption(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Invalid account address");
        isFeeExempt[account] = exempt;
    }

    /**
     * @notice Updates the fee wallet addresses.
     * @param _burnWallet      New burn wallet address.
     * @param _utilityWallet   New utility wallet address.
     * @param _liquidityWallet New liquidity wallet address.
     */
    function updateWallets(
        address _burnWallet,
        address _utilityWallet,
        address _liquidityWallet
    ) external onlyOwner {
        require(_burnWallet != address(0), "Burn wallet cannot be zero");
        require(_utilityWallet != address(0), "Utility wallet cannot be zero");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero");

        burnWallet = _burnWallet;
        utilityWallet = _utilityWallet;
        liquidityWallet = _liquidityWallet;
    }
}
