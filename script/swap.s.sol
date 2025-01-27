// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CLPoolRouter} from "../src/CLPoolRouter.sol";

contract DeployCLPoolRouter is Script {
    function run() public returns (CLPoolRouter) {
        vm.startBroadcast();

        CLPoolRouter swapTest = new CLPoolRouter();

        vm.stopBroadcast();
        return swapTest;
    }
}