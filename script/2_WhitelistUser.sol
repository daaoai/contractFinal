// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure
contract WhitelistUser is Script {

    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address DAO_CONTRACT_ADDRESS = 0x29F07AA75328194C274223F11cffAa329fD1c319;

        Daao daosWorldV1 = Daao(DAO_CONTRACT_ADDRESS);

        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = 0x34A132A8A19B72661B58E46A6eB25ac44b73cAc5;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        // First send some MODE tokens to the contract
        daosWorldV1.addOrUpdateWhitelist(users, tiers);

        // update tier limit if required
        daosWorldV1.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        vm.stopBroadcast();

    }
}