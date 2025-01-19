// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Pool.sol";

contract DeployPool is Script {
    // Replace these with appropriate addresses before deployment
    address constant TOKEN0 = 0xYourToken0AddressHere;
    address constant TOKEN1 = 0xYourToken1AddressHere;
    bool constant STABLE = true; // Set to false for volatile pools

    function run() external {
        vm.startBroadcast();

        // Deploy the Pool contract
        Pool pool = new Pool();

        // Initialize the Pool contract
        pool.initialize(TOKEN0, TOKEN1, STABLE);

        console.log("Pool deployed to:", address(pool));
        console.log("Pool token0:", pool.token0());
        console.log("Pool token1:", pool.token1());
        console.log("Pool type:", STABLE ? "Stable" : "Volatile");

        vm.stopBroadcast();
    }
}
