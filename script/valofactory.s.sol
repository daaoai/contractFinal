// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PoolFactory.sol";

contract DeployPoolFactory is Script {
    function run() external {
        // Define deployment parameters
        address implementation = 0xYourImplementationAddressHere; // Replace with the actual implementation contract address

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the PoolFactory contract
        PoolFactory poolFactory = new PoolFactory(implementation);

        // Log the deployed contract address
        console.log("PoolFactory deployed at:", address(poolFactory));

        // Set additional configurations if needed
        address initialVoter = msg.sender; // Replace with the desired voter address
        address initialPauser = msg.sender; // Replace with the desired pauser address
        address feeManager = msg.sender; // Replace with the desired fee manager address

        // Configure the PoolFactory contract
        poolFactory.setVoter(initialVoter);
        poolFactory.setPauser(initialPauser);
        poolFactory.setFeeManager(feeManager);

        // Log configurations
        console.log("Voter set to:", initialVoter);
        console.log("Pauser set to:", initialPauser);
        console.log("Fee Manager set to:", feeManager);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
