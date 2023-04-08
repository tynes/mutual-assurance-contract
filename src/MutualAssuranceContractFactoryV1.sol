// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ClonesWithImmutableArgs } from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import { MutualAssuranceContractV1 } from "./MutualAssuranceContractV1.sol";
import { GnosisSafeProxyFactory } from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "safe-contracts/GnosisSafe.sol";

/// @title MutualAssuranceContractFactoryV1
/// @author tynes
/// @notice A factory used create MutualAssuranceContractV1 contracts.
contract MutualAssuranceContractFactoryV1 {
    using ClonesWithImmutableArgs for address;

    /// @notice A reference to the implementation of the MutualAssuranceContractV1. This is the code
    //          that users will interact with when they create a new instance of a
    //          MutualAssuranceContractV1.
    MutualAssuranceContractV1 public immutable implementation;

    /// @notice A reference to the GnosisSafeProxyFactory.
    GnosisSafeProxyFactory public immutable safeFactory;

    /// @notice A reference to the GnosisSafe singleton.
    GnosisSafe public immutable safeSingleton;

    /// @notice Emitted when a MutualAssuranceContractV1 is created, includes the address of the
    ///         MutualAssuranceContractV1.
    event Create(address);

    /// @notice Errors when required data is not included when creating a MutualAssuranceContractV1.
    error Empty();

    /// @notice Set up the system by deploying a MutualAssuranceContractV1 implementation. This
    //          implementation has references to the GnosisSafe contracts and is used to create
    //          cheap clones-with-immutable-args clones for each instance of a mutual assurace contract.
    constructor(GnosisSafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) {
        implementation = new MutualAssuranceContractV1(_safeFactory, _safeSingleton);
        safeFactory = _safeFactory;
        safeSingleton = _safeSingleton;
    }

    /// @notice Create a MutualAssuranceContractV1 instance.
    /// @param _commitment Represents a name for the MutualAssuranceContractV1.
    /// @param _duration   The number of seconds that the MutualAssuranceContractV1 should be open
    //                     for participation.
    /// @param _lump       The amount of wei that must accumulate in the contract for it to resolve
    ///                    to winning.
    /// @param _guardians  The owners of the GnosisSafe that is created when the MutualAssuranceContractV1
    ///                    resolves to winning.
    function create(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address[] memory _guardians
    ) external returns (MutualAssuranceContractV1) {
        if (_lump == 0 || _guardians.length == 0) revert Empty();

        bytes memory data = abi.encodePacked(_commitment, _duration, _lump);
        address clone = address(implementation).clone(data);
        MutualAssuranceContractV1 instance = MutualAssuranceContractV1(payable(clone));
        instance.initialize(_guardians);

        emit Create(address(instance));
        return instance;
    }
}
