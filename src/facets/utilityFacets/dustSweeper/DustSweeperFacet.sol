// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DustSweeperStorage} from "./DustSweeperStorage.sol";
import {UniswapBase} from "../uniswap/UniswapBase.sol";
import {IDustSweeper} from "./IDustSweeper.sol";
import {Facet} from "../../Facet.sol";

// Minimal Uniswap V3 Factory interface
interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

contract DustSweeperFacet is Facet, UniswapBase, IDustSweeper {
    using SafeERC20 for IERC20;

    // USDT address on Arbitrum
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    
    // Uniswap V3 Factory on Arbitrum
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    
    // Uniswap V3 fee tiers to try (0.05%, 0.3%, 1%)
    uint24[3] private FEE_TIERS = [500, 3000, 10000];

    /**
     * @notice Sweep multiple dust tokens into USDT
     * @param tokens Array of token addresses to sweep
     * @param amounts Array of amounts for each token
     * @param minUsdtOut Minimum USDT to receive (slippage protection)
     */
    function sweepDust(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minUsdtOut
    ) external override returns (uint256 totalUsdtReceived) {
        require(tokens.length == amounts.length, "DustSweeper: Length mismatch");
        require(tokens.length > 0, "DustSweeper: No tokens");

        DustSweeperStorage.Layout storage s = DustSweeperStorage.layout();
        
        // Transfer all tokens from user to Diamond
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != USDT, "DustSweeper: Cannot sweep USDT");
            IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
        }

        // Swap each token to USDT
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 usdtReceived = _swapToUsdt(tokens[i], amounts[i]);
            totalUsdtReceived += usdtReceived;
        }

        require(totalUsdtReceived >= minUsdtOut, "DustSweeper: Slippage too high");

        // Update user's USDT balance in Diamond storage
        s.userBalances[msg.sender] += totalUsdtReceived;
        s.totalUsdtHeld += totalUsdtReceived;

        emit DustSwept(msg.sender, tokens, amounts, totalUsdtReceived);
    }



    /**
     * @notice Sweep dust tokens that are stuck in the Diamond contract itself
     * @dev Only callable by Diamond owner. Tokens must already be in Diamond contract.
     * @param tokens Array of token addresses to sweep from Diamond
     * @param amounts Array of amounts for each token (0 = sweep full balance)
     * @param minUsdtOut Minimum USDT to receive (slippage protection)
     */
    function sweepGardenDust(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minUsdtOut
    ) external override onlyDiamondOwner returns (uint256 totalUsdtReceived) {
        require(tokens.length == amounts.length, "DustSweeper: Length mismatch");
        require(tokens.length > 0, "DustSweeper: No tokens");

        DustSweeperStorage.Layout storage s = DustSweeperStorage.layout();
        
        // Swap each token to USDT (tokens are already in Diamond)
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != USDT, "DustSweeper: Cannot sweep USDT");
            
            // Use actual balance if amount is 0 or greater than balance
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            uint256 amountToSwap = amounts[i] == 0 || amounts[i] > tokenBalance 
                ? tokenBalance 
                : amounts[i];
            
            require(amountToSwap > 0, "DustSweeper: No balance to sweep");
            
            uint256 usdtReceived = _swapToUsdt(tokens[i], amountToSwap);
            totalUsdtReceived += usdtReceived;
        }

        require(totalUsdtReceived >= minUsdtOut, "DustSweeper: Slippage too high");

        // Credit USDT to owner's balance (can be withdrawn later)
        s.userBalances[msg.sender] += totalUsdtReceived;
        s.totalUsdtHeld += totalUsdtReceived;

        emit GardenDustSwept(msg.sender, tokens, amounts, totalUsdtReceived);
    }

    /**
     * @notice Withdraw USDT from Diamond
     * @param amount Amount of USDT to withdraw
     */
    function withdrawUsdt(uint256 amount) external override {
        DustSweeperStorage.Layout storage s = DustSweeperStorage.layout();
        
        require(s.userBalances[msg.sender] >= amount, "DustSweeper: Insufficient balance");
        
        s.userBalances[msg.sender] -= amount;
        s.totalUsdtHeld -= amount;
        IERC20(USDT).safeTransfer(msg.sender, amount);

        emit UsdtWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Get user's USDT balance in Diamond
     */
    function getUsdtBalance(address user) external view override returns (uint256) {
        return DustSweeperStorage.layout().userBalances[user];
    }

    /**
     * @notice Internal function to swap any token to USDT  
     */
    function _swapToUsdt(address tokenIn, uint256 amountIn) internal returns (uint256 usdtOut) {
        // Skip if token is already USDT
        if (tokenIn == USDT) {
            return amountIn;
        }
        
        // Use only the 0.05% fee tier (500) which we know exists from tests
        return _swapExactInputSingle(
            tokenIn,
            USDT,
            500, // Use 0.05% fee tier
            amountIn,
            0, // No minimum for dust amounts
            address(this)
        );
    }
}