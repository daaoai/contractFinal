// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {LockerFactory} from "../src/LockerFactory.sol";
import {console2} from "forge-std/console2.sol";
contract DeployLockerFactory is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        console2.log("deployed",deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        LockerFactory lockerFactory = new LockerFactory();
        console2.log("LockerFactory deployed at:", address(lockerFactory));

        vm.stopBroadcast();
    }
}

