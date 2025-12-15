// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DustSweeperFacet} from "src/facets/utilityFacets/dustSweeper/DustSweeperFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {IDustSweeper} from "src/facets/utilityFacets/dustSweeper/IDustSweeper.sol";

contract DeployDustSweeperFacet is Script {
    function run() external {
        // Get deployment parameters from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        
        console.log("=== Deploying DustSweeper Facet ===");
        console.log("Diamond address:", diamondAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the DustSweeperFacet
        DustSweeperFacet dustSweeperFacet = new DustSweeperFacet();
        console.log("DustSweeperFacet deployed at:", address(dustSweeperFacet));

        // 2. Prepare function selectors
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = IDustSweeper.sweepDust.selector;
        functionSelectors[1] = IDustSweeper.withdrawUsdt.selector;
        functionSelectors[2] = IDustSweeper.getUsdtBalance.selector;

        console.log("Function selectors prepared:", functionSelectors.length);

        // 3. Prepare the diamond cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(dustSweeperFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // 4. Execute the diamond cut
        console.log("Adding DustSweeper Facet to Diamond...");
        IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");
        
        console.log("DustSweeperFacet added to Diamond successfully!");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Diamond:", diamondAddress);
        console.log("DustSweeperFacet:", address(dustSweeperFacet));
        console.log("Functions added:", functionSelectors.length);
        console.log("\n=== Facet Functions ===");
        console.log("1. sweepDust(address[],uint256[],uint256)");
        console.log("2. withdrawUsdt(uint256)");
        console.log("3. getUsdtBalance(address)");
        
    }
}