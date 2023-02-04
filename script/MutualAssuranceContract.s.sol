// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";
import { console } from "forge-std/console.sol";

contract MutualAssuranceFactoryScript is Script, Test {
    address constant station = 0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77;

    function run() public {
        vm.broadcast();
        MutualAssuranceContractFactory factory = new MutualAssuranceContractFactory{ salt: 0x00 }(station);
        console.log("factory address:", address(factory));

        assertEq(address(factory.STATION()), station);
    }
}
