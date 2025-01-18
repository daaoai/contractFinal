// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {DaosWorldV1} from "../src/DaosWorldV1.sol"; // Adjust path if needed
import {DaosWorldV1Token} from "../src/DaosWorldV1Token.sol"; // Adjust path if needed

contract FinalizeFundraising is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Address of the deployed DaosWorldV1 contract
        address payable daosWorldV1Address = payable(vm.envAddress("DAOS_WORLD_V1_ADDRESS")); // Add the deployed address to .env
        DaosWorldV1 daosWorldV1 = DaosWorldV1(daosWorldV1Address);

        // Address of the deployed token contract
        address daosWorldV1TokenAddress = vm.envAddress("DAOS_WORLD_V1_TOKEN_ADDRESS"); // Add the deployed address to .env
        DaosWorldV1Token daosWorldV1Token = DaosWorldV1Token(daosWorldV1TokenAddress);

        // Initial tick and upper tick values for Uniswap V3 pool
        int24 initialTick = -276330; // Replace with your calculated initial tick
        int24 upperTick = 276330;   // Replace with your calculated upper tick

        // Set the DAO token in the DaosWorldV1 contract
        daosWorldV1.setDaoToken(daosWorldV1TokenAddress);
        console2.log("DAO token set to:", daosWorldV1TokenAddress);

        // Finalize the fundraising
        daosWorldV1.finalizeFundraising(initialTick, upperTick);
        console2.log("Fundraising finalized for contract:", daosWorldV1Address);

        vm.stopBroadcast();
    }
}
