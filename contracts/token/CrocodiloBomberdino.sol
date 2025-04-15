// SPDX-License-Identifier: MIT
event FeeExemptionUpdated(address indexed account, bool exempt);
event FeeWalletsUpdated(address indexed burn, address indexed utility, address indexed liquidity);
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
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
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;


    /**
     * @dev Initializes the contract: sets token details, mints the total supply,
     *      initializes fee wallet addresses and fee percentages,
     *      and exempts the deployer and the contract itself from fees.
     */
    function initialize() public initializer {
        __ERC20_init("Crocodilo Bomberdino", "CROCBO");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        // Mint the full supply to the deployer (owner)
        _mint(msg.sender, INITIAL_SUPPLY);

        // Set initial fee wallet addresses (replace with secure addresses before mainnet deployment)
        burnWallet = 0x077da53e0865f111B35912d400822bA89401Ca64;
        utilityWallet = 0x775AFE34497a187350607d669c097DD9F6DDfaad;
        liquidityWallet = 0xd42509a701A192ce204E5FB1be4fBa0C8b08a982;

        // Initialize fee percentages
        burnFee = 2;        // 2% burn fee
        utilityFee = 2;     // 2% utility fee
        liquidityFee = 1;   // 1% auto-liquidity fee
        

        // Exempt the deployer (owner) and the contract itself from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

function _transfer(address sender, address recipient, uint256 amount) internal override {
    if (isFeeExempt[sender] || isFeeExempt[recipient]) {
        super._transfer(sender, recipient, amount);
    } else {
        require(totalFee() <= 100, "Fee too high"); // Changed to <= 100 to allow 5%
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
}