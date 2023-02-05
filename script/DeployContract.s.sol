// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";
import { console2 as console } from "forge-std/console2.sol";
import { stdJson } from "forge-std/StdJson.sol";


/**
* @title  MutualAssuranceContractScript
* @notice Deploy an instance of a mutual assurance contract
*/
contract DeployContract is Script, Test {
    address factory;

    // Parsed config
    bytes32 commitment;
    uint256 duration;
    uint256 lump;
    address commander;
    address[] players;

    function _readJson(string memory json) internal view returns (string memory) {
      string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
      string memory chainDir = string.concat(vm.toString(block.chainid), "/");
      string memory file = string.concat(json, ".json");
      return vm.readFile(string.concat(inputDir, chainDir, file));
    }

    /**
     * @notice Read the config file from disk that is generated by the factory
     *         deploy script.
     */
    function setUp() public {
        string memory config = _readJson("config");
        factory = stdJson.readAddress(config, "factory");
        console.log("Using factory:", factory);
    }

    /**
     * @notice Parse the config file. Return abi encoded bytes to be able
     *         to access the data from running `forge script`
     */
    function _parseArgs(string memory input) public returns (bytes memory) {
        string memory config = _readJson(input);
        string memory _commitment = stdJson.readString(config, "commitment");
        if (bytes(_commitment).length < 32) {
            commitment = bytes32(bytes(_commitment));
        } else {
            commitment = keccak256(abi.encodePacked(_commitment));
        }
        duration = stdJson.readUint(config, "duration");
        lump = stdJson.readUint(config, "lump");
        commander = stdJson.readAddress(config, "commander");
        players = stdJson.readAddressArray(config, "players");

        return abi.encode(
            commitment,
            duration,
            lump,
            commander,
            players
        );
    }

    /**
     * @notice Execute the deployment. There must be a config file on disk for
     *         the instance of the mutual assurance contract. Pass in the name
     *         of the file containing the config without the `.json` suffix.
     */
    function run(string memory input) public returns (address) {
        _parseArgs(input);

        console.log("commitment:", vm.toString(commitment));
        console.log("duration:", duration);
        console.log("lump:", lump);
        console.log("commander:", commander);
        console.log("players:");
        for (uint256 i; i < players.length; i++) {
            console.log(" ", players[i]);
        }

        vm.broadcast();
        address mas = MutualAssuranceContractFactory(factory).deploy({
            _commitment: commitment,
            _duration: duration,
            _lump: lump,
            _commander: commander,
            _players: players
        });

        console.log("Mutual Assurance Contract Address:", mas);

        return mas;
    }
}