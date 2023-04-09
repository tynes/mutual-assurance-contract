// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ClonesWithImmutableArgs } from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import { Pact } from "./Pact.sol";
import { GnosisSafeProxyFactory } from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "safe-contracts/GnosisSafe.sol";

/// @title PactFactory
/// @author tynes
/// @notice A factory used create Pact contracts.
contract PactFactory {
    using ClonesWithImmutableArgs for address;

    /// @notice A reference to the implementation of the Pact. This is the code
    //          that users will interact with when they create a new instance of a
    //          Pact.
    Pact public immutable implementation;

    /// @notice A reference to the GnosisSafeProxyFactory.
    GnosisSafeProxyFactory public immutable safeFactory;

    /// @notice A reference to the GnosisSafe singleton.
    GnosisSafe public immutable safeSingleton;

    /// @notice Emitted when a Pact is created, includes the address of the
    ///         Pact.
    event Create(address);

    /// @notice Errors when required data is not included when creating a Pact.
    error Empty();

    /// @notice Set up the system by deploying a Pact implementation. This
    //          implementation has references to the GnosisSafe contracts and is used to create
    //          cheap clones-with-immutable-args clones for each instance of a mutual assurace contract.
    constructor(GnosisSafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) {
        implementation = new Pact(_safeFactory, _safeSingleton);
        safeFactory = _safeFactory;
        safeSingleton = _safeSingleton;
    }

    /// @notice Create a Pact instance.
    /// @param _commitment Represents a name for the Pact.
    /// @param _duration   The number of seconds that the Pact should be open
    //                     for participation.
    /// @param _lump       The amount of wei that must accumulate in the contract for it to resolve
    ///                    to winning.
    /// @param _guardians  The owners of the GnosisSafe that is created when the Pact
    ///                    resolves to winning.
    function create(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address[] memory _guardians
    ) external returns (Pact) {
        if (_lump == 0 || _guardians.length == 0) revert Empty();

        bytes memory data = abi.encodePacked(_commitment, _duration, _lump);
        address clone = address(implementation).clone(data);
        Pact instance = Pact(payable(clone));
        instance.initialize(_guardians);

        emit Create(address(instance));
        return instance;
    }
}
