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

        // 2. Prepare the arguments for `initialize()`

        // integrationAddresses_ => [projectOwner, uniswapRouter, pairToken]
        address[3] memory integrationAddresses = [
            msg.sender, // projectOwner
            0x6AD9F54098EdA3A6577c379516EC934d6873851F, // uniswapRouter
            0x462B0cB16834E33654265380999A9B6310C709B9  // pairToken
        ];

        // baseParams_ => (string name, string symbol)
        bytes memory baseParams_ = abi.encode("DAOs Token", "DAsO");

        // supplyParams_ => (address vault, uint64 maxSupply, uint64 vaultSupply, uint64 lpSupply, uint32 botProtectionDurationInSeconds)
        bytes memory supplyParams_ = abi.encode(
            msg.sender, // vault address
            uint64(1_000_000), // maxSupply
            uint64(500_000),   // vaultSupply
            uint64(500_000),   // lpSupply
            uint32(3600)       // botProtectionDurationInSeconds (1 hour)
        );

       // ERC20TaxParameters = (uint16 buy, uint16 sell, uint16 threshold, address recipient)

bytes memory taxParams_ = abi.encode(
    uint16(100),  // projectBuyTaxBasisPoints   (1%)
    uint16(200),  // projectSellTaxBasisPoints  (2%)
    uint16(50),   // taxSwapThresholdBasisPoints (0.5%)
    msg.sender  // projectTaxRecipient
);

   

// Decode in Solidity to verify the values match the expected structure

        // 3. Call the `initialize` method
        agentToken.initialize(
            integrationAddresses,
            baseParams_,
            supplyParams_,
            taxParams_
        );

        // Log the deployed AgentToken address
        console2.log("AgentToken deployed at:", address(agentToken));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
