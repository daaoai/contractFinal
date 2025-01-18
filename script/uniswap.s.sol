// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/uniswap/UniswapV3Factory.sol";

contract DeployUniswapV3Factory is Script {
    function run() external {
        // Load deployer account from Foundry
        address deployer = vm.envAddress("DEPLOYER_ADDRESS"); // Load DEPLOYER_ADDRESS from environment variables
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY"); // Load DEPLOYER_PRIVATE_KEY from environment variables

        vm.startBroadcast(privateKey);

        // Deploy the UniswapV3Factory contract
        UniswapV3Factory factory = new UniswapV3Factory();

        console.log("UniswapV3Factory deployed at:", address(factory));
        console.log("Owner is:", factory.owner());

        vm.stopBroadcast();
    }
}
