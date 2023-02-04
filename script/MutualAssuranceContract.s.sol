// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";

contract MutualAssuranceFactoryScript is Script {
    address constant station = 0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77;

    // TODO: how to handle private keys?
    function setUp() public {}

    function run() public {
        vm.broadcast();
        MutualAssuranceContractFactory factory = new MutualAssuranceContractFactory(station);
    }
}
