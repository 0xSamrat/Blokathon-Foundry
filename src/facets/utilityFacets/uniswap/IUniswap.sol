// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IUniswap
 * @notice Interface for Uniswap V3 integration facet
 */
interface IUniswap {
    // Events
    event TokensSwapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed recipient
    );
    
    event LiquidityAdded(
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    
    event LiquidityRemoved(
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    // Swap functions
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut);

    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external returns (uint256 amountIn);

    // Liquidity functions
    function addLiquidity(
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function removeLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 amount0, uint256 amount1);

    // View functions
    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address pool);

    function getQuote(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    // Configuration
    function setSwapRouter(address _swapRouter) external;
    function setNonfungiblePositionManager(address _positionManager) external;
    function getSwapRouter() external view returns (address);
    function getNonfungiblePositionManager() external view returns (address);
}