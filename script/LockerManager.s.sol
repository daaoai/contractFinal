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
//LockerFactory deployed at: 0x1d2aCE3BccE9E1321a2AB8eaf9e3241dAc71b8fD
// DaosWorldV1Token deployed at: 0x462B0cB16834E33654265380999A9B6310C709B9
 // DaosWorldV1 deployed at: 0xAa90e743bADc66A05EdA2E37181baf8f9970F351
  //Daos manager is  0xaA53cb2CCb70684476480AED76e31179729d2a92
  //Adding to whitelist and contributing...

