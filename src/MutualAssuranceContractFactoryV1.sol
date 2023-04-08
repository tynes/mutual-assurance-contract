// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ClonesWithImmutableArgs } from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import { MutualAssuranceContractV1 } from "./MutualAssuranceContractV1.sol";
import { SafeProxyFactory } from "safe-contracts/proxies/SafeProxyFactory.sol";

// prediction markets are a zero sum game

contract MutualAssuranceContractFactoryV1 {
    using ClonesWithImmutableArgs for address;

    MutualAssuranceContractV1 public immutable implementation;
    SafeProxyFactory public immutable safeFactory;
    GnosisSafe public immutable safeSingleton;

    constructor(SafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) {
        implementation = = new MutualAssuranceContractV1(_safeFactory, _safeSingleton);
        safeFactory = _safeFactory;
        safeSingleton = _safeSingleton;
    }

    function create(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address[] memory _guardians
    ) external returns (MutualAssuranceContractV1) {
        bytes memory data = abi.encodePacked(_commitment, _duration, _lump);
        address clone = address(implementation).clone(data);
        MutualAssuranceContractV1 instance = MutualAssuranceContractV1(payable(clone));
        instance.initialize(_guardians);
        return instance;
    }
}
