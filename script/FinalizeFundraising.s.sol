// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {DaosWorldV1} from "../src/DaosWorldV1.sol"; 
import {DaosWorldV1Token} from "../src/DaosWorldV1Token.sol"; 

contract FinalizeFundraising is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

       
        address payable daosWorldV1Address = payable(vm.envAddress("DAOS_WORLD_V1_ADDRESS")); 
        DaosWorldV1 daosWorldV1 = DaosWorldV1(daosWorldV1Address);

        address daosWorldV1TokenAddress = vm.envAddress("DAOS_WORLD_V1_TOKEN_ADDRESS"); 
        DaosWorldV1Token daosWorldV1Token = DaosWorldV1Token(daosWorldV1TokenAddress);

       
        int24 initialTick = 6800; 
        int24 upperTick = 7200;   


        daosWorldV1.finalizeFundraising(initialTick, upperTick);
        console2.log("Fundraising finalized for contract:", daosWorldV1Address);

        vm.stopBroadcast();
    }
}
