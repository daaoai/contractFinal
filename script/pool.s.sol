// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/velo/pool/Pool.sol";

contract DeployPool is Script {
    // Replace these with appropriate addresses before deployment
    address constant TOKEN0 = 0xb3a227E89972137b8A4573E7B4779950207BF264;
    address constant TOKEN1 = 0xcc9ffcfBDFE629e9C62776fF01a75235F466794E;
    bool constant STABLE = true; // Set to false for volatile pools

    function run() external {
        vm.startBroadcast();

        // Deploy the Pool contract
        Pool pool = new Pool();

   

        console.log("Pool deployed to:", address(pool));
        console.log("Pool token0:", pool.token0());
        console.log("Pool token1:", pool.token1());
        console.log("Pool type:", STABLE ? "Stable" : "Volatile");

        vm.stopBroadcast();
    }
}
