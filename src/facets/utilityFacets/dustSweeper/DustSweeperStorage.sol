// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DustSweeperStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("blok.storage.dustsweeper");

    struct Layout {
        // User address => USDT balance
        mapping(address => uint256) userBalances;
        
        // Total USDT held in contract
        uint256 totalUsdtHeld;
        
        // Minimum dust value to sweep ($10 in wei)
        uint256 minDustValue;
        
        // Fee percentage (basis points, 100 = 1%)
        uint256 feeBps;
        
        // Fee collector address
        address feeCollector;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}