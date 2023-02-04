// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";
import { MutualAssuranceContract } from "../src/MutualAssuranceContract.sol";
import { IAttestationStation } from "../src/IAttestationStation.sol";

/**
 * @notice
 */
contract MutualAssuranceContractTest is Test {
    IAttestationStation constant station = IAttestationStation(0xEE36eaaD94d1Cc1d0eccaDb55C38bFfB6Be06C77);
    MutualAssuranceContractFactory public factory;

    address alice;
    address bob;

    bytes32 internal constant ContractCreatedTopic = keccak256("ContractCreated(bytes32,address,address[])");
    bytes32 internal constant AttestationCreatedTopic = keccak256("AttestationCreated(address,address,bytes32,bytes)");

    function setUp() external {
        factory = new MutualAssuranceContractFactory(address(station));
        vm.label(address(station), "AttestationStation");

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        deal(alice, 100 ether);
        deal(bob, 100 ether);
    }

    /**
     * @notice The AttestationStation contract should be set in the
     *         constructor and be accessible via a getter
     */
    function test_constructor() external {
        assertEq(
            address(factory.STATION()),
            address(station)
        );
    }

    function _deploy() internal returns (address) {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        return _deploy(players);
    }

    function _deploy(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address[] memory _players
    ) internal returns (address) {
        return factory.deploy(
            _commitment,
            _duration,
            _lump,
            _commander,
            _players
        );
    }

    function _deploy(address[] memory _players) internal returns (address) {
        bytes32 commitment = keccak256("foo");
        uint256 duration = 100;
        uint256 lump = 250;
        address commander = address(0xdd);

        return factory.deploy(
            commitment,
            duration,
            lump,
            commander,
            _players
        );
    }

    function test_initial_attestors() external {
        // record the logs of the deployment
        vm.recordLogs();
        address c = _deploy();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // instance of the mutual assurance contract
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        assertEq(m.FACTORY(), address(factory));
        assertEq(address(m.STATION()), address(station));

        // grab the ContractCreated event, there is only 1 of them
        address[] memory players;
        bytes32 commitment;
        address assuraceContract;
        for (uint256 i; i < entries.length; i++) {
            if (entries[i].topics[0] == ContractCreatedTopic) {
                commitment = entries[i].topics[1];
                assuraceContract = address(uint160(uint256(entries[i].topics[2])));
                players = abi.decode(entries[i].data, (address[]));
            }
        }

        assertTrue(players.length > 0);
        assertTrue(commitment != bytes32(0));
        assertTrue(assuraceContract != address(0));
        assertEq(c, assuraceContract);

        // ensure that the attestations are set up properly
        for (uint256 i; i < players.length; i++) {
            bytes memory a = station.attestations(address(factory), players[i], commitment);
            assertTrue(a.length != 0);
            address val = abi.decode(a, (address));
            assertEq(val, c);
        }

        // ensure that the players are allowed
        for (uint256 i; i < players.length; i++) {
            assertEq(
                m.isAllowed(players[i]),
                true
            );
        }

        address[] memory factoryPlayers = factory.players(assuraceContract);
        assertEq(factoryPlayers.length, players.length);

        for (uint256 i; i < factoryPlayers.length; i++) {
            assertEq(factoryPlayers[i], players[i]);
        }
    }

    //
    function test_resolve_win() external {
        address c = _deploy();
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        uint256 lump = m.LUMP();
        vm.prank(alice);
        c.call{ value: lump }(hex"");
        vm.warp(m.END());
        assertEq(m.isResolvable(), true);

        m.resolve();
    }
}
