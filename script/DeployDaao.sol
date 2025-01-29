// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure

contract DeployDaosWorld is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DaaoToken
        DaaoToken token = new DaaoToken("TdsToken", "TOD");
        console2.log("DaaoToken deployed at:", address(token));

        // Deploy Daao

        uint256 fundraisingGoal = 0.000001 ether; // 100
        uint256 maxWhitelistAmount = 0.1 ether; // Max 10 ETH per whitelist
        uint256 maxPublicContributionAmount = 20 ether; // Max 20 ETH for public contribution

        uint256 fundraisingDeadline = block.timestamp + 7 days; // 7 days from now

        uint256 fundExpiry = fundraisingDeadline + 30 days; // 30 days after deadline

        address daoManager = vm.addr(deployerPrivateKey); // Address derived from the deployer private key
        address liquidityLockerFactory = address(
            0xaEDEDdDC448AEE5237f6b3f11Ec370aB5793A0d3
        ); // Replace with actual address

        address protocolAdmin = daoManager; // Protocol admin same as DAO manager

        // Daao daosWorldV1 = new Daao(
        //     fundraisingGoal,
        //     "DAO Token",
        //     "DAO",
        //     fundraisingDeadline,
        //     fundExpiry,
        //     daoManager,
        //     liquidityLockerFactory,
        //     maxWhitelistAmount,
        //     protocolAdmin,
        //     maxPublicContributionAmount
        // );
        token.transferOwnership(
            address(0x4B4f3C9126197fcCF0d92fBA0C194F0DffF16072)
        );

        console2.log("Daos manager is ", daoManager);
    }
}
