// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {LpLocker} from "../src/LpLocker.sol";

contract DeployLpLocker is Script {
    function run() public {
        // Load deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Starting LpLocker deployment...");

        // Deployment parameters
        address v3PositionManager = 0xEF3e32154B5Fb96D56D339e655A5edf5f5661Af8; // Replace with actual address
        address daoManager = vm.addr(deployerPrivateKey); // DAO manager (deployer)
        uint256 fundExpiry = block.timestamp + 30 days; // Fund expiry 30 days from now
        uint256 protocolFee = 60; // Protocol fee (e.g., 60 means 60%)
        address protocolAdmin =msg.sender ; // Replace with protocol admin address
        address daoTreasury = 0x65e3064cd3d75a440367B1d0C433a2de0aFCcB57; // Replace with DAO treasury address

        // Deploy LpLocker contract
        LpLocker lpLocker = new LpLocker(
            v3PositionManager,
            daoManager,
            fundExpiry,
            protocolFee,
            protocolAdmin
        );

        console2.log("LpLocker deployed at:", address(lpLocker));

        // Initialize the contract with a token ID (replace with actual token ID)
        uint256 tokenId = 1; // Example token ID
        lpLocker.initializer(tokenId);

        console2.log("LpLocker initialized with token ID:", tokenId);

        vm.stopBroadcast();
    }
}
