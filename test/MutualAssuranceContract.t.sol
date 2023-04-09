// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { GnosisSafeProxyFactory } from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "safe-contracts/GnosisSafe.sol";
import { PactFactory } from "../src/PactFactory.sol";
import { Pact } from "../src/Pact.sol";

/// @notice Test the mutual assurance contract
contract MutualAssuranceContractTest is Test {
    event Assurance(address who, uint256 value);
    event Resolve(bool);

    // both accounts are from mainnet
    GnosisSafeProxyFactory constant safeFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
    GnosisSafe constant safeSingleton = GnosisSafe(payable(0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552));

    address internal alice;
    address internal bob;
    address internal charlie;

    PactFactory internal factory;

    /// @notice Set up the test env
    function setUp() external {
        factory = new PactFactory({
            _safeFactory: safeFactory,
            _safeSingleton: safeSingleton
        });

        vm.label(address(safeFactory), "GnosisSafeProxyFactory");
        vm.label(address(safeSingleton), "GnosisSafe");

        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(charlie, 100 ether);

        _setupSafe();
    }

    /// @notice Sets the GnosisSafe related code at the correct addresses.
    function _setupSafe() internal skipWhenForking {
        vm.etch(address(safeFactory), vm.getDeployedCode("GnosisSafeProxyFactory.sol"));
        vm.etch(address(safeSingleton), vm.getDeployedCode("GnosisSafe.sol"));
    }

    /// @notice Deploys a standard MutualAssuranceContract for testing. Alice and Bob
    ///         are leads and Charlie is not.
    function _deploy() internal returns (Pact) {
        address[] memory _leads = new address[](2);
        _leads[0] = alice;
        _leads[1] = bob;
        string memory agreement = "i like turtles";

        return _deploy(_leads, agreement);
    }

    /// @notice Deploy a Pact with configurable leads.
    function _deploy(address[] memory _leads, string memory _agreement) internal returns (Pact) {
        bytes32 commitment = factory.commit(_agreement);

        Pact pact = factory.create({
            _commitment: commitment,
            _duration: 12 * 500,
            _sum: 1 ether,
            _leads: _leads
        });

        vm.label(address(pact), "pact");
        return pact;
    }

    /// @notice Refactor into a builder pattern if we need more configurable
    ///         pacts.
    function _deploy(string memory _agreement) internal returns (Pact) {
        address[] memory leads = new address[](2);
        leads[0] = alice;
        leads[1] = bob;

        return _deploy(leads, _agreement);
    }

    function _deploy(address[] memory _leads) internal returns (Pact) {
        string memory agreement = "i like turtles";
        return _deploy(_leads, agreement);
    }

    /// @notice Ensures that the constructor initializes the factory correctly
    function test_factory_constructor() external {
        address _safeFactory = address(factory.safeFactory());
        assertEq(_safeFactory, address(safeFactory));
        assertTrue(_safeFactory.code.length > 0);

        address _safeSingleton = address(factory.safeSingleton());
        assertEq(_safeSingleton, address(safeSingleton));
        assertTrue(_safeSingleton.code.length > 0);

        address pact = address(factory.pact());
        assertTrue(pact != address(0));
        assertTrue(pact.code.length != 0);
    }

    /// @notice Ensures that a factory can be created with sane config
    function test_factory_create() external {
        address[] memory _leads = new address[](1);
        _leads[0] = alice;

        bytes32 commitment = keccak256(abi.encode(block.timestamp));
        uint256 duration = 1e6;
        uint256 sum = 30 ether;

        Pact pact = factory.create({
            _commitment: commitment,
            _duration: duration,
            _sum: sum,
            _leads: _leads
        });

        vm.label(address(pact), "pact");

        assertEq(address(pact.safeFactory()), address(safeFactory));
        assertEq(address(pact.safeSingleton()), address(safeSingleton));

        assertEq(pact.resolved(), false);
        assertEq(pact.start(), block.timestamp);

        assertEq(pact.duration(), duration);
        assertEq(pact.sum(), sum);
        assertEq(pact.commitment(), commitment);
        assertEq(pact.leads(), _leads);
        assertEq(address(pact.safe()), address(0));
    }

    /// @notice Creation reverts when no value is configured to be able to win.
    function test_factory_createNosumReverts() external {
        address[] memory _leads = new address[](1);
        _leads[0] = alice;

        vm.expectRevert(abi.encodeWithSelector(PactFactory.Empty.selector));
        factory.create({
            _commitment: bytes32(uint256(1)),
            _duration: 0,
            _sum: 0,
            _leads: _leads
        });
    }

    /// @notice Creation reverts when no leads are configured.
    function test_factory_createNoleadsReverts() external {
        address[] memory _leads = new address[](0);

        vm.expectRevert(abi.encodeWithSelector(PactFactory.Empty.selector));
        factory.create({
            _commitment: bytes32(uint256(1)),
            _duration: 0,
            _sum: 1 ether,
            _leads: _leads
        });
    }

    /// @notice Any user can contribute.
    function test_pact_contribute() external {
        Pact pact = _deploy();

        uint256 value = 1 ether;

        vm.expectEmit(true, true, true, true, address(pact));
        emit Assurance(alice, value);

        vm.prank(alice);
        (bool success, ) = address(pact).call{ value: value }(hex"");
        assertTrue(success);

        assertEq(address(pact).balance, value);

        Pact.Contribution[] memory contribs = pact.contributions();
        assertEq(contribs.length, 1);

        Pact.Contribution memory contrib = contribs[0];
        assertEq(contrib.from, alice);
        assertEq(contrib.amount, value);

        Pact.Contribution memory contribution = pact.contribution(0);
        assertEq(contribution.from, alice);
        assertEq(contribution.amount, value);
    }

    /// @notice The commitment feature works as expected.
    function test_pact_commit() external {
        string memory commitment = "I solemnly swear that I am up to no good";
        Pact pact = _deploy(commitment);
        assertEq(factory.commit(commitment), pact.commitment());
    }

    /// @notice Ensures that all the side effects of winning a pact are correct.
    function test_pact_win() external {
        address[] memory leads = new address[](1);
        leads[0] = alice;

        Pact pact = _deploy(leads);

        // Add enough value
        uint256 value = pact.sum();

        vm.expectEmit(true, true, true, true, address(pact));
        emit Assurance(alice, value);

        vm.prank(alice);
        (bool success, ) = address(pact).call{ value: value }(hex"");
        assertTrue(success);
        // The pact should have enough value
        assertEq(address(pact).balance, value);

        // Move time to the end
        uint256 end = pact.end();
        vm.warp(end);

        // It should be resolvable and continuing
        assertTrue(pact.resolvable());
        assertTrue(pact.continuing());

        vm.expectEmit(true, true, true, true, address(pact));
        emit Resolve(true);

        vm.prank(bob);
        pact.resolve();

        assertTrue(pact.resolved());

        assertEq(address(pact).balance, 0);

        GnosisSafe safe = pact.safe();
        assertTrue(address(safe).code.length > 0);

        address[] memory owners = safe.getOwners();
        assertEq(leads, owners);
        assertEq(safe.getThreshold(), owners.length);
        assertEq(address(safe).balance, value);
    }

    /// @notice Test a failed resolution
    function test_pact_lose() external {
        address[] memory leads = new address[](1);
        leads[0] = alice;

        Pact pact = _deploy(leads);

        uint256 alicePreBalance = alice.balance;

        uint256 value = pact.sum() - 1;

        vm.expectEmit(true, true, true, true, address(pact));
        emit Assurance(alice, value);

        vm.prank(alice);
        (bool success, ) = address(pact).call{ value: value }(hex"");
        assertTrue(success);

        uint256 end = pact.end();
        vm.warp(end);

        assertTrue(pact.resolvable());
        assertFalse(pact.continuing());

        vm.expectEmit(true, true, true, true, address(pact));
        emit Resolve(false);

        vm.expectCall(alice, value, hex"");

        vm.prank(bob);
        pact.resolve();

        uint256 alicePostBalance = alice.balance;
        assertEq(alicePostBalance, alicePreBalance);
    }
}
