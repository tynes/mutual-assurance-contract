// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";
import { PactFactory } from "../src/PactFactory.sol";
import { Pact } from "../src/Pact.sol";
import { console } from "forge-std/console.sol";
import { DeployFactory } from "./DeployFactory.s.sol";

/// @title  MutualAssuranceContractScript
/// @notice Deploy an instance of a mutual assurance contract
contract DeployContract is Script {
    /// @notice Errors if a constant needs to be updated.
    error UpdateConstant(string);

    /// @notice Deterministic deployment address of the PactFactory.
    ///         This needs to be updated if there is a diff to the bytecode or the create2
    ///         salt changes.
    address internal constant factory = 0x363a186CaEAb9388fE2c80357D6ceB97B0C3b5C8;

    /// @notice Deploys the factory if necessary.
    function setUp() public {
        if (address(factory).code.length == 0) {
            DeployFactory deployFactory = new DeployFactory();
            address addr = deployFactory.run();
            if (addr != factory && block.chainid != 31337) revert UpdateConstant("PactFactory");
        }
    }

    /// @notice Top level deployment function for creating new mutual assurance contracts.
    function run(bytes memory _input) public returns (address) {
        (
            bytes32 commitment,
            uint256 duration,
            uint256 sum,
            address[] memory leads
        ) = abi.decode(_input, (bytes32, uint256, uint256, address[]));

        console.log("commitment:", vm.toString(commitment));
        console.log("duration:", duration);
        console.log("sum:", sum);
        console.log("leads:");
        for (uint256 i; i < leads.length; i++) {
            console.log(" ", leads[i]);
        }

        vm.broadcast();
        Pact pact = PactFactory(factory).create({
            _commitment: commitment,
            _duration: duration,
            _sum: sum,
            _leads: leads
        });

        address addr = address(pact);
        console.log("Mutual Assurance Contract Address:", addr);

        return addr;
    }
}
