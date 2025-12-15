// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IUniswap} from "src/facets/utilityFacets/uniswap/IUniswap.sol";

contract ConfigureUniswap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        
        // Uniswap V3 addresses on Arbitrum
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address positionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        
        console.log("=== Configuring Uniswap Facet ===");
        console.log("Diamond:", diamondAddress);
        console.log("Swap Router:", swapRouter);
        console.log("Position Manager:", positionManager);
        
        vm.startBroadcast(deployerPrivateKey);

        IUniswap uniswap = IUniswap(diamondAddress);
        
        uniswap.setSwapRouter(swapRouter);
        uniswap.setNonfungiblePositionManager(positionManager);
        
        console.log("\n=== Configuration Complete ===");
        console.log("Configured Router:", uniswap.getSwapRouter());
        console.log("Configured Position Manager:", uniswap.getNonfungiblePositionManager());

        vm.stopBroadcast();
    }
}
