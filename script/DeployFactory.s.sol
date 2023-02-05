// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";
import { console } from "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";

contract MutualAssuranceFactoryScript is Script, Test {
    address constant station = 0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77;

    function outfile() internal view returns (string memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        return string.concat(inputDir, chainDir, "config.json");
    }

    function run() public {
        vm.broadcast();
        MutualAssuranceContractFactory factory = new MutualAssuranceContractFactory{ salt: bytes32(uint256(0x01)) }(station);
        console.log("factory address:", address(factory));

        assertEq(address(factory.STATION()), station);

        string memory json = "";
        json = stdJson.serialize(json, "factory", address(factory));
        stdJson.write(json, outfile());
    }
}
