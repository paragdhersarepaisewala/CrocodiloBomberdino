// SPDX-License-Identifier: MIT
event FeeExemptionUpdated(address indexed account, bool exempt);
event FeeWalletsUpdated(address indexed burn, address indexed utility, address indexed liquidity);

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "contracts/token/utils/FeeManager.sol";

contract CrocodiloBomberdino is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, FeeManager, PausableUpgradeable {
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;

    function initialize() public initializer {
        __ERC20_init("Crocodilo Bomberdino", "CROCBO");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __Pausable_init();
        _mint(msg.sender, INITIAL_SUPPLY);
        burnWallet = 0x077da53e0865f111B35912d400822bA89401Ca64;
        utilityWallet = 0x775AFE34497a187350607d669c097DD9F6DDfaad;
        liquidityWallet = 0xd42509a701A192ce204E5FB1be4fBa0C8b08a982;
        burnFee = 2;
        utilityFee = 2;
        liquidityFee = 1;
        isFeeExempt[msg.sender] = false;
        isFeeExempt[address(this)] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual whenNotPaused {}

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        _beforeTokenTransfer(sender, recipient, amount);
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            require(totalFee() <= 100, "Fee too high");
            if (totalFee() == 0) revert("Fees not initialized");
            uint256 feeTotal = (amount * totalFee()) / 100;
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 utilityAmount = (amount * utilityFee) / 100;
            uint256 liquidityAmount = feeTotal - burnAmount - utilityAmount;
            super._transfer(sender, burnWallet, burnAmount);
            super._transfer(sender, utilityWallet, utilityAmount);
            super._transfer(sender, liquidityWallet, liquidityAmount);
            super._transfer(sender, recipient, amount - feeTotal);
        }
    }

    function updateFeeExemption(address account, bool exempt) external onlyOwner {
        require(account != address(0), "Invalid account address");
        isFeeExempt[account] = exempt;
        emit FeeExemptionUpdated(account, exempt);
    }

    function updateWallets(address _burnWallet, address _utilityWallet, address _liquidityWallet) external onlyOwner {
        require(_burnWallet != address(0), "Burn wallet cannot be zero");
        require(_utilityWallet != address(0), "Utility wallet cannot be zero");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero");
        burnWallet = _burnWallet;
        utilityWallet = _utilityWallet;
        liquidityWallet = _liquidityWallet;
        emit FeeWalletsUpdated(_burnWallet, _utilityWallet, _liquidityWallet);
    }

    function updateFees(uint256 _burn, uint256 _utility, uint256 _liquidity) external onlyOwner {
        require(_burn + _utility + _liquidity <= 10, "Total fee too high");
        burnFee = _burn;
        utilityFee = _utility;
        liquidityFee = _liquidity;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}