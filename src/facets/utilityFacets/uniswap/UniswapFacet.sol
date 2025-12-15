// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UniswapBase} from "./UniswapBase.sol";
import {UniswapStorage} from "./UniswapStorage.sol";
import {IUniswap} from "./IUniswap.sol";
import {OwnershipStorage} from "src/facets/baseFacets/ownership/OwnershipStorage.sol";

/**
 * @title UniswapFacet
 * @notice Facet for Uniswap V3 integration
 * @dev Exposes public functions for swapping and liquidity management
 */
contract UniswapFacet is UniswapBase, IUniswap {
    
    modifier onlyOwner() {
        require(
            msg.sender == OwnershipStorage.layout().owner,
            "UniswapFacet: Must be contract owner"
        );
        _;
    }

    // ============ Swap Functions ============

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external override returns (uint256 amountOut) {
        amountOut = _swapExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            amountOutMinimum,
            recipient
        );

        emit TokensSwapped(tokenIn, tokenOut, amountIn, amountOut, recipient);
    }

    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external override returns (uint256 amountIn) {
        amountIn = _swapExactOutputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountOut,
            amountInMaximum,
            recipient
        );

        emit TokensSwapped(tokenIn, tokenOut, amountIn, amountOut, recipient);
    }

    // ============ Liquidity Functions ============

    function addLiquidity(
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient
    ) external override returns (uint256 amount0, uint256 amount1, uint256 liquidity) {
        // Use default tick range for simplicity (can be parameterized)
        int24 tickLower = -887220; // Min tick
        int24 tickUpper = 887220;  // Max tick

        (amount0, amount1, liquidity) = _addLiquidity(
            token0,
            token1,
            fee,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min,
            recipient,
            tickLower,
            tickUpper
        );

        emit LiquidityAdded(token0, token1, amount0, amount1, liquidity);
    }

    function removeLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) external override returns (uint256 amount0, uint256 amount1) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        
        require(
            s.positionOwner[tokenId] == msg.sender,
            "UniswapFacet: Not position owner"
        );

        (amount0, amount1) = _removeLiquidity(
            tokenId,
            liquidity,
            amount0Min,
            amount1Min
        );

        emit LiquidityRemoved(address(0), address(0), amount0, amount1);
    }

    // ============ View Functions ============

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) external view override returns (address pool) {
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        bytes32 key = _getPoolKey(token0, token1, fee);
        return s.pools[key];
    }

    function getQuote(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {
        // This would require implementing a quoter call
        // For now, return 0 - implement based on your needs
        return 0;
    }

    // ============ Configuration Functions ============

    function setSwapRouter(address _swapRouter) external override onlyOwner {
        require(_swapRouter != address(0), "UniswapFacet: Invalid address");
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        s.swapRouter = _swapRouter;
    }

    function setNonfungiblePositionManager(address _positionManager) 
        external 
        override 
        onlyOwner 
    {
        require(_positionManager != address(0), "UniswapFacet: Invalid address");
        UniswapStorage.Layout storage s = UniswapStorage.layout();
        s.nonfungiblePositionManager = _positionManager;
    }

    function getSwapRouter() external view override returns (address) {
        return UniswapStorage.layout().swapRouter;
    }

    function getNonfungiblePositionManager() external view override returns (address) {
        return UniswapStorage.layout().nonfungiblePositionManager;
    }
}