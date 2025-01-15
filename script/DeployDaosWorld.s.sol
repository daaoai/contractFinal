// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaosWorldV1Token} from "../src/DaosWorldV1Token.sol"; // Adjust the path based on your project structure
import {DaosWorldV1} from "../src/DaosWorldV1.sol"; // Adjust the path based on your project structure

contract DeployDaosWorld is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DaosWorldV1Token
        DaosWorldV1Token token = new DaosWorldV1Token("DaoTest", "TOD");
        console2.log("DaosWorldV1Token deployed at:", address(token));

        // Deploy DaosWorldV1


        uint256 fundraisingGoal = 100 ether; // 100 
        uint256 maxWhitelistAmount = 10 ether; // Max 10 ETH per whitelist
        uint256 maxPublicContributionAmount = 20 ether; // Max 20 ETH for public contribution
       


        uint256 fundraisingDeadline = block.timestamp + 7 days; // 7 days from now
      
 uint256 fundExpiry = fundraisingDeadline + 30 days; // 30 days after deadline
        
        address daoManager = vm.addr(deployerPrivateKey); // Address derived from the deployer private key
        address liquidityLockerFactory = address(0x4086781DB8a2f843C7917a56e462f4A19c5537eb); // Replace with actual address
     
        address protocolAdmin = daoManager; // Protocol admin same as DAO manager


        DaosWorldV1 daosWorldV1 = new DaosWorldV1(
            fundraisingGoal,
            "DAO Token",
            "DAO",
            fundraisingDeadline,
            fundExpiry,
            daoManager,
            liquidityLockerFactory,
            maxWhitelistAmount,
            protocolAdmin,
            maxPublicContributionAmount
        );
        console2.log("DaosWorldV1 deployed at:", address(daosWorldV1));
        console2.log("Daos manager is ",daoManager);
       
    }
}
