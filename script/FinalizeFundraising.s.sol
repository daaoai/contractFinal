// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {Daao} from "../src/Daao.sol";
import {DaaoToken} from "../src/DaaoToken.sol";

contract FinalizeFundraising is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address payable daosWorldV1Address = payable(
            vm.envAddress("DAOS_WORLD_V1_ADDRESS")
        );
        Daao daosWorldV1 = Daao(daosWorldV1Address);

        address daosWorldV1TokenAddress = vm.envAddress(
            "DAOS_WORLD_V1_TOKEN_ADDRESS"
        );

        int24 initialTick = 6800;
        int24 upperTick = 7200;

        daosWorldV1.finalizeFundraising(initialTick, upperTick);
        console2.log("Fundraising finalized for contract:", daosWorldV1Address);

        vm.stopBroadcast();
    }
}
