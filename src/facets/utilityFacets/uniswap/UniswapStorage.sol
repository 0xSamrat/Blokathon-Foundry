// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UniswapStorage
 * @notice Diamond storage for Uniswap facet
 * @dev Uses Diamond Storage pattern to avoid storage collisions
 */
library UniswapStorage {
    bytes32 internal constant STORAGE_SLOT = 
        keccak256("blok.storage.uniswap");

    struct Layout {
        // Uniswap V3 contract addresses
        address swapRouter;              // ISwapRouter
        address nonfungiblePositionManager; // INonfungiblePositionManager
        address quoter;                  // IQuoter (for price quotes)
        
        // Position tracking
        mapping(uint256 => address) positionOwner; // tokenId => owner
        mapping(address => uint256[]) userPositions; // user => tokenIds
        
        // Pool tracking
        mapping(bytes32 => address) pools; // keccak256(token0, token1, fee) => pool
        
        // Slippage settings
        uint256 defaultSlippageBps; // Default slippage in basis points (100 = 1%)
        
        // Fee tiers commonly used
        uint24[] feeTiers; // e.g., [500, 3000, 10000] for 0.05%, 0.3%, 1%
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}