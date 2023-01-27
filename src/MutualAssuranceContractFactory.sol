// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAttestationStation } from "./IAttestationStation.sol";
import { MutualAssuranceContract } from "./MutualAssuranceContract.sol";

/**
 * @title
 */
contract MutualAssuranceContractFactory {
    /**
     * @notice
     */
    IAttestationStation immutable STATION;

    /**
     * @notice
     */
    event ContractCreated(
        bytes32 indexed _commitment,
        address _contract,
        address[] _players
    );

    constructor(address _station) {
        STATION = IAttestationStation(_station);
    }

    function deploy(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address[] memory _players
    ) public {
        MutualAssuranceContract c = new MutualAssuranceContract(
            _commitment,
            _duration,
            _lump,
            _commander,
            address(STATION)
        );

        uint256 length = _players.length;
        IAttestationStation.AttestationData[] memory a = new IAttestationStation.AttestationData[](length);

        unchecked {
            for (uint256 i; i < length; ++i) {
                a[i] = IAttestationStation.AttestationData({
                    about: _players[i],
                    key: _commitment,
                    val: abi.encode(address(c))
                });
            }
        }

        STATION.attest(a);

        emit ContractCreated(_commitment, address(c), _players);
    }
}

