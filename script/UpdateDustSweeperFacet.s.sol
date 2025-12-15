// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DustSweeperFacet} from "src/facets/utilityFacets/dustSweeper/DustSweeperFacet.sol";
import {IDiamondCut} from "src/facets/baseFacets/cut/IDiamondCut.sol";
import {IDustSweeper} from "src/facets/utilityFacets/dustSweeper/IDustSweeper.sol";

contract UpdateDustSweeperFacet is Script {
    function run() external {
        // Get deployment parameters from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        
        console.log("=== Updating DustSweeper Facet ===");
        console.log("Diamond address:", diamondAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the new DustSweeperFacet
        DustSweeperFacet dustSweeperFacet = new DustSweeperFacet();
        console.log("New DustSweeperFacet deployed at:", address(dustSweeperFacet));

        // 2. Prepare function selectors
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IDustSweeper.sweepDust.selector;
        functionSelectors[1] = IDustSweeper.sweepGardenDust.selector;
        functionSelectors[2] = IDustSweeper.withdrawUsdt.selector;
        functionSelectors[3] = IDustSweeper.getUsdtBalance.selector;

        console.log("Function selectors prepared:", functionSelectors.length);

        // 3. Prepare the diamond cut - Replace existing functions and Add new sweepGardenDust
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        
        // Replace existing 3 functions
        bytes4[] memory replaceSelectors = new bytes4[](3);
        replaceSelectors[0] = IDustSweeper.sweepDust.selector;
        replaceSelectors[1] = IDustSweeper.withdrawUsdt.selector;
        replaceSelectors[2] = IDustSweeper.getUsdtBalance.selector;
        
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(dustSweeperFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });
        
        // Add new sweepGardenDust function
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = IDustSweeper.sweepGardenDust.selector;
        
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(dustSweeperFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        // 4. Execute the diamond cut
        console.log("Updating DustSweeper Facet in Diamond...");
        IDiamondCut(diamondAddress).diamondCut(cut, address(0), "");
        
        console.log("DustSweeperFacet replaced successfully!");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== Update Summary ===");
        console.log("Diamond:", diamondAddress);
        console.log("New DustSweeperFacet:", address(dustSweeperFacet));
        console.log("Functions updated:", functionSelectors.length);
        console.log("\n=== Facet Functions ===");
        console.log("1. sweepDust(address[],uint256[],uint256) - [REPLACED]");
        console.log("2. sweepGardenDust(address[],uint256[],uint256) - [ADDED]");
        console.log("3. withdrawUsdt(uint256) - [REPLACED]");
        console.log("4. getUsdtBalance(address) - [REPLACED]");
    }
}
