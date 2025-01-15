// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DAOTreasury} from "../src/DAOTreasury.sol";
import {console2} from "forge-std/console2.sol";
contract DeployDAOTreasury is Script {
    function run() public {
        // Start the deployment process
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the DAOTreasury contract
        DAOTreasury daoTreasury = new DAOTreasury();
        console2.log("DAO Treasury deployed at:", address(daoTreasury));

        // Optionally, make the first deposit to the treasury
        daoTreasury.deposit{value: 0.0003 ether}();

        console2.log("1 ether deposited into the DAO Treasury.");

        vm.stopBroadcast();
    }
}
