// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapStorage} from "./UniswapStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uniswap V3 interfaces (you'll need to import these)
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

/**
 * @title UniswapBase
 * @notice Base contract with internal logic for Uniswap operations
 */
abstract contract UniswapBase {
    using SafeERC20 for IERC20;

    // Internal swap function
    function _swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) internal returns (uint256 amountOut) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        
        require(s.swapRouter != address(0), "UniswapBase: Router not set");
        require(amountIn > 0, "UniswapBase: Invalid amount");

        // Approve router to spend tokens (force approve to handle tokens with existing allowance)
        IERC20(tokenIn).forceApprove(s.swapRouter, amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = ISwapRouter(s.swapRouter).exactInputSingle(params);
    }

    function _swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) internal returns (uint256 amountIn) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        
        require(s.swapRouter != address(0), "UniswapBase: Router not set");
        require(amountOut > 0, "UniswapBase: Invalid amount");

        // Approve router (force approve to handle tokens with existing allowance)
        IERC20(tokenIn).forceApprove(s.swapRouter, amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: recipient,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = ISwapRouter(s.swapRouter).exactOutputSingle(params);

        // Refund unused tokens
        if (amountIn < amountInMaximum) {
            IERC20(tokenIn).forceApprove(s.swapRouter, 0);
        }
    }

    function _addLiquidity(
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint256 amount0, uint256 amount1, uint256 liquidity) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        
        require(s.nonfungiblePositionManager != address(0), "UniswapBase: Manager not set");

        // Approve position manager (force approve to handle tokens with existing allowance)
        IERC20(token0).forceApprove(s.nonfungiblePositionManager, amount0Desired);
        IERC20(token1).forceApprove(s.nonfungiblePositionManager, amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: recipient,
                deadline: block.timestamp
            });

        (uint256 tokenId, uint128 liquidityAmount, uint256 amt0, uint256 amt1) = 
            INonfungiblePositionManager(s.nonfungiblePositionManager).mint(params);

        // Track position
        s.positionOwner[tokenId] = recipient;
        s.userPositions[recipient].push(tokenId);

        return (amt0, amt1, uint256(liquidityAmount));
    }

    function _removeLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        
        require(s.nonfungiblePositionManager != address(0), "UniswapBase: Manager not set");

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = 
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        (amount0, amount1) = INonfungiblePositionManager(s.nonfungiblePositionManager)
            .decreaseLiquidity(params);
    }

    function _getPoolKey(
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token1, fee));
    }
}