// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract DeployDaosWorld is Script {

    address public constant MODE_TOKEN_ADDRESS = 0xDfc7C877a950e49D2610114102175A06C2e3167a;
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Daao

        uint256 fundraisingGoal = 10 ether; // 100 MODE

        uint256 fundraisingDeadline = block.timestamp + 7 days; // 1 day from now

        uint256 fundExpiry = fundraisingDeadline + 30 days; // 1 day after deadline

        address daoManager = vm.addr(deployerPrivateKey); // Address derived from the deployer private key
        address liquidityLockerFactory = address(0xaEDEDdDC448AEE5237f6b3f11Ec370aB5793A0d3); // Replace with actual address

        address protocolAdmin = daoManager; // Protocol admin same as DAO manager

        Daao daosWorldV1 = new Daao(
            fundraisingGoal,
            "Cartel Test Token",
            "CARTELTEST",
            fundraisingDeadline,
            fundExpiry,
            daoManager,
            liquidityLockerFactory,
            protocolAdmin
        );

        console2.log("Daos manager is ", daoManager); // 0x6F1313f206dB52139EB6892Bfd88aC9Ae36Dc54E
        console2.log("DaosWorldV1 is ", address(daosWorldV1)); //0x147f235Dde1adcB00Ef8E2D10D98fEd9a091284D

        vm.stopBroadcast();

    }
}
