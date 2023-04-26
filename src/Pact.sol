// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Clone } from "clones-with-immutable-args/Clone.sol";
import { GnosisSafeProxyFactory } from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafeProxy } from "safe-contracts/proxies/GnosisSafeProxy.sol";
import { GnosisSafe } from "safe-contracts/GnosisSafe.sol";
import { SafeCall } from "./SafeCall.sol";

/// @title Pact
/// @author tynes
/// @notice A mutual assurance contract is a mechanism meant to lower the cost of coordination.
///         A pre-agreed upon outcome is easier to reach as additional credible commitments
///         are added. Ether can be sent to the contract and if a pre-agreed upon amount is
///         accumulated within a pre-agreed amount of time, the coordination can continue.
///         If not, the group disbands and all ether is returned.
/// @dev    A new GnosisSafe is created when continuing and all ether is transferred to it.
///         It is expected that the pre-agreed upon commitment is observed. The rule of law
///         dictates meatspace.
contract Pact is Clone {
    string constant public version = "0.3.0";

    /// @notice Used to determine if the pact has been initialized.
    bool internal _initialized;

    /// @notice Indicates the resolution status of the pact. When resolved, it
    //          is no longer possible to interact with the pact.
    bool public resolved;

    /// @notice Used as a reentrency guard.
    uint256 internal _wall;

    /// @notice The starting time of the Pact.
    uint256 public start;

    /// @notice The address of the GnosisSafe proxy that is created after the Pact
    ///         resolves to winning. It is set to `address(0)` if the contract has not resolved yet.
    GnosisSafe public safe;

    /// @notice The set of accounts that own the GnosisSafe that is created after a winning
    //          resolution.
    address[] internal _leads;

    /// @notice The set of contributions. It is permissionless to contribute.
    Contribution[] internal _contributions;

    /// @notice The address of the GnosisSafeProxyFactory. Used to create an instance of a safe
    ///         when the Pact resolves to winning.
    GnosisSafeProxyFactory public immutable safeFactory;

    /// @notice The address of the GnosisSafe singleton. This is the implementation that the
    ///         instance of the proxy created by the factory will delegatecall.
    GnosisSafe public immutable safeSingleton;

    /// @notice Emitted when the Pact resolves. It will no longer accept funds
    //          after it resolves.
    event Resolve(bool);

    /// @notice Emitted when funds are sent to the contract.
    event Assurance(address, uint256);

    /// @notice Error when trying to resolve a contract that has already been resolved.
    error Resolved();

    /// @notice Error when reentrency.
    error Reentrant();

    /// @notice Error when trying to resolve the Pact too early.
    error Early();

    /// @notice Error when putting too much value into the Pact.
    error Overflow();

    /// @notice Error when trying to `initialize()` when the Pact has
    ///         already been initialized.
    error Initialized();

    /// @notice Represents a contribution to the mutual assurance contract.
    struct Contribution {
        address from;
        uint256 amount;
    }

    /// @notice Track immutable references to the GnosisSafeProxyFactory and GnosisSafe singleton.
    constructor(GnosisSafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) {
        safeFactory = _safeFactory;
        safeSingleton = _safeSingleton;
        // No money can be sent to the singleton.
        resolved = true;
    }

    /// @notice Send ether directly to this contract to contribute. All contributions are tracked
    ///         so that ether can be returned in case not enough capital is accumulated.
    fallback() external payable {
        if (resolved) revert Resolved();
        if (address(this).balance > sum()) revert Overflow();

        address sender = msg.sender;
        uint256 value = msg.value;

        _contributions.push(Contribution(sender, value));

        emit Assurance(sender, value);
    }

    /// @notice A name for the Pact picked by the creator.
    function commitment() public pure returns (bytes32) {
        return bytes32(_getArgUint256(0));
    }

    /// @notice The length of the Pact in seconds.
    function duration() public pure returns (uint256) {
        return _getArgUint256(32);
    }

    /// @notice The amount of wei required to make the Pact resolve to winning.
    function sum() public pure returns (uint256) {
        return _getArgUint256(64);
    }

    /// @notice The timestamp in which the Pact can resolve.
    function end() public view returns (uint256) {
        return duration() + start;
    }

    /// @notice Convenience getter for the balance in the Pact.
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Useful for ensuring that the agreement matches the commitment.
    function check(string memory _agreement) public pure returns (bool) {
        return keccak256(bytes(_agreement)) == commitment();
    }

    /// @notice The set of leads will own the GnosisSafe that is created after
    ///         a winning resolution. All funds are transferred to this GnosisSafe.
    function leads() public view returns (address[] memory) {
        uint256 length = _leads.length;
        address[] memory gs = new address[](length);
        for (uint256 i; i < length;) {
            gs[i] = _leads[i];
            unchecked { ++i; }
        }
        return gs;
    }

    /// @notice The set of contributions to the Pact. Each contribution
    ///         includes the account that sent the value and the amount of value sent.
    function contributions() public view returns (Contribution[] memory) {
        uint256 length = _contributions.length;
        Contribution[] memory contribs = new Contribution[](length);
        for (uint256 i; i < length;) {
            contribs[i] = _contributions[i];
            unchecked { ++i; }
        }
        return contribs;
    }

    /// @notice Gets a particular contribution.
    function contribution(uint256 _index) public view returns (Contribution memory) {
        return _contributions[_index];
    }

    /// @notice Responsible for setting the storage that the contract needs to function.
    ///         This should be called by the factory directly after being deployed.
    function initialize( address[] memory _gs) public {
        if (_initialized) revert Initialized();

        start = block.timestamp;
        _initialized = true;
        _wall = 1;

        uint256 length = _gs.length;
        for (uint256 i; i < length;) {
            _leads.push(_gs[i]);
            unchecked { ++i; }
        }
    }

    /// @notice prevent reentrency
    modifier nonreentrant() {
        if (_wall == 0) revert Reentrant();
        _wall = 0;
        _;
        _wall = 1;
    }

    /// @notice Determine if the contract is resolvable. If this returns true, then `resolve()` can
    //          be called.
    function resolvable() public view returns (bool) {
        return block.timestamp >= end();
    }

    /// @notice Determine if the contract will resolve to winning. The balance must be larger than
    //          or equal to the sum.
    function continuing() public view returns (bool) {
        return address(this).balance >= sum();
    }

    /// @notice Call this to resolve the contract. It will be no longer possible to contribute funds
    ///         and the contract will either resolve to winning or losing. When the contract
    //          resolves to winning, it will create a GnosisSafe with the leads set as the
    //          owners and then transfer all funds to that contract. When the contract resolves to
    //          losing, it will return the money to each contributor. To resolve to winning, the
    //          contract must have enough value in it.
    function resolve() external nonreentrant {
        // ensure it can only be resolved once
        if (resolved) revert Resolved();

        // ensure enough time has passed
        if (!resolvable()) revert Early();

        bool success = continuing();

        // effects
        resolved = true;

        // interactions
        if (success) _continue();
        else _disband();

        emit Resolve(success);
    }

    /// @notice Creates a GnosisSafe and transfers all of the value in this contract to the
    ///         Gnosis safe.
    function _continue() internal {
        GnosisSafeProxy proxy = safeFactory.createProxyWithNonce({
            _singleton: address(safeSingleton),
            initializer: _safeInitializer(),
            saltNonce: _safeNonce()
        });

        _transfer(address(proxy), address(this).balance);

        safe = GnosisSafe(payable(address(proxy)));
    }

    /// @notice Refunds all contributors to the Pact.
    function _disband() internal {
        uint256 length = _contributions.length;
        for (uint256 i; i < length;) {
            Contribution memory c = _contributions[i];
            _transfer(c.from, c.amount);
            unchecked { ++i; }
        }
    }

    /// @notice Helper function for sending value.
    function _transfer(address _to, uint256 _amount) internal {
        SafeCall.call({
            _target: _to,
            _gas: gasleft(),
            _value: _amount,
            _calldata: hex""
        });
    }

    /// @notice Encodes GnosisSafe `setup` calldata. Used to initialize the newly deployed
    ///         GnosisSafe.
    function _safeInitializer() internal view returns (bytes memory) {
        address[] memory gs = leads();
        return abi.encodeCall(
            GnosisSafe.setup,
            (
                gs,                  // owners
                gs.length,           // threshold
                address(0),          // to
                hex"",               // data
                address(0),          // fallbackHandler
                address(0),          // paymentToken
                0,                   // payment
                payable(address(0))  // paymentReceiver
            )
        );
    }

    /// @notice Creates a nonce suitable for `create2` for the GnosisSafe.
    function _safeNonce() internal view returns (uint256) {
        return uint256(uint160(address(this)));
    }
}
