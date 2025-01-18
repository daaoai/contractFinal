// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {AgentToken} from "../src/Agent/AgentToken.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @notice Script to deploy the AgentToken and initialize it with specific parameters.
 */
contract DeployAgentTokenScript is Script {

    function run() external returns (AgentToken agentToken) {
        // Start broadcasting transactions using the private key
        vm.startBroadcast();

        // 1. Deploy the AgentToken contract
        agentToken = new AgentToken();

        // Log the deployed AgentToken address
        console2.log("AgentToken deployed at:", address(agentToken));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
