// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { MutualAssuranceContractFactory } from "../src/MutualAssuranceContractFactory.sol";
import { MutualAssuranceContract } from "../src/MutualAssuranceContract.sol";
import { IAttestationStation } from "../src/IAttestationStation.sol";

/**
 * @notice Test the mutual assurance contract
 */
contract MutualAssuranceContractTest is Test {
    event Assurance(address who, uint256 value);
    event Resolved(bool);

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

    /**
     * @notice Wrap the factory deploy
     */
    function _deploy() internal returns (address) {
        address[] memory players = new address[](2);
        players[0] = alice;
        players[1] = bob;

        return _deploy(players);
    }

    /**
     * @notice Wrap the factory deploy
     */
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

    /**
     * @notice Wrap the factory deploy
     */
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

    /**
     * @notice The initial setup of attestations.
     */
    function test_initial_attestors() external {
        // record the logs of the deployment
        vm.recordLogs();
        address c = _deploy();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // instance of the mutual assurance contract
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        assertEq(m.FACTORY(), address(factory), "Factory address mismatch");
        assertEq(address(m.STATION()), address(station), "Station address mismatch");

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

        assertTrue(players.length > 0, "No players found");
        assertTrue(commitment != bytes32(0), "No commitment found");
        assertTrue(assuraceContract != address(0), "No contract found");
        assertEq(c, assuraceContract, "Contract address mismatch");

        // ensure that the attestations are set up properly
        for (uint256 i; i < players.length; i++) {
            bytes memory a = station.attestations(c, players[i], bytes32("player"));
            assertTrue(a.length != 0, "No attestation found");
            assertEq(hex"01", a, "Unexpected data in attestation");
        }

        // ensure that the players are allowed
        for (uint256 i; i < players.length; i++) {
            assertTrue(m.isAllowed(players[i]), "Player not allowed");
        }

        address[] memory factoryPlayers = factory.players(assuraceContract);
        assertEq(factoryPlayers.length, players.length);

        for (uint256 i; i < factoryPlayers.length; i++) {
            assertEq(factoryPlayers[i], players[i], "Fetched players incorrect");
        }
    }

    /**
     * @notice Test a winning resolution
     */
    function test_resolve_win() external {
        address c = _deploy();
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        uint256 lump = m.LUMP();

        vm.expectEmit(true, true, true, true, c);
        emit Assurance(alice, lump);

        vm.prank(alice);
        (bool success, ) = c.call{ value: lump }(hex"");
        assertTrue(success);

        vm.warp(m.END());
        assertEq(m.isResolvable(), true);

        uint256 prebalance = c.balance;

        vm.expectEmit(true, true, true, true, c);
        emit Resolved(true);

        vm.expectCall(
            m.COMMANDER(),
            prebalance,
            hex""
        );
        m.resolve();

        assertEq(m.COMMANDER().balance, prebalance);
    }

    /**
     * @notice Test contributing more than once and updating the attestation
     *         value
     */
    function test_contribute_twice() external {
        address c = _deploy();
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        vm.prank(alice);
        (bool s1, ) = c.call{ value: 10 }(hex"");
        assertTrue(s1);

        vm.prank(alice);
        (bool s2, ) = c.call{ value: 10 }(hex"");
        assertTrue(s2);

        bytes memory a = station.attestations(c, alice, m.TOPIC());
        uint256 total = abi.decode(a, (uint256));
        assertEq(total, 20);
    }

    /**
     * @notice Test a failed resolution
     */
    function test_resolve_lose() external {
        address c = _deploy();
        MutualAssuranceContract m = MutualAssuranceContract(payable(c));

        uint256 prebalance = alice.balance;

        uint256 lump = m.LUMP();
        vm.prank(alice);
        (bool success, ) = c.call{ value: lump - 1 }(hex"");
        assertTrue(success);

        bytes memory a = station.attestations(c, alice, m.TOPIC());
        uint256 total = abi.decode(a, (uint256));
        assertEq(total, lump - 1);

        vm.warp(m.END());
        assertEq(m.isResolvable(), true);

        vm.expectEmit(true, true, true, true, c);
        emit Resolved(false);

        vm.expectCall(alice, lump - 1, hex"");
        m.resolve();

        assertEq(alice.balance, prebalance);
    }
}
