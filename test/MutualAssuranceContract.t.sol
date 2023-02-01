// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";

contract MutualAssuranceContractTest {
    address constant station = 0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77;
    MutualAssuranceContractFactory public f;

    function setUp() external {
        f = new MutualAssuranceContractFactory(station);
    }

    function test_foo() external {
        console.log(address(f));
    }
}
