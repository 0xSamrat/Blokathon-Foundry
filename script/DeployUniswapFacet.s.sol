// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {UniswapFacet} from "src/facets/utilityFacets/uniswap/UniswapFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {IUniswap} from "src/facets/utilityFacets/uniswap/IUniswap.sol";

contract DeployUniswapFacet is Script {
    function run() external {
        // Get deployment parameters from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        
        console.log("=== Deploying Uniswap Facet ===");
        console.log("Diamond address:", diamondAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the UniswapFacet
        UniswapFacet uniswapFacet = new UniswapFacet();
        console.log("UniswapFacet deployed at:", address(uniswapFacet));

        // 2. Prepare function selectors
        bytes4[] memory functionSelectors = new bytes4[](10);
        functionSelectors[0] = IUniswap.swapExactInputSingle.selector;
        functionSelectors[1] = IUniswap.swapExactOutputSingle.selector;
        functionSelectors[2] = IUniswap.addLiquidity.selector;
        functionSelectors[3] = IUniswap.removeLiquidity.selector;
        functionSelectors[4] = IUniswap.getPool.selector;
        functionSelectors[5] = IUniswap.getQuote.selector;
        functionSelectors[6] = IUniswap.setSwapRouter.selector;
        functionSelectors[7] = IUniswap.setNonfungiblePositionManager.selector;
        functionSelectors[8] = IUniswap.getSwapRouter.selector;
        functionSelectors[9] = IUniswap.getNonfungiblePositionManager.selector;

        console.log("Function selectors prepared:", functionSelectors.length);

        // 3. Prepare the diamond cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(uniswapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // 4. Execute the diamond cut
        console.log("Adding Uniswap Facet to Diamond...");
        IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");
        
        console.log("UniswapFacet added to Diamond successfully!");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Diamond:", diamondAddress);
        console.log("UniswapFacet:", address(uniswapFacet));
        console.log("Functions added:", functionSelectors.length);
        console.log("\n=== Next Steps ===");
        console.log("1. Configure Uniswap router addresses");
        console.log("2. Test swap functionality");
    }
}