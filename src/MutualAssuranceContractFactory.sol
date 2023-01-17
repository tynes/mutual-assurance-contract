// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAttestationStation } from "./IAttestationStation.sol";
import { MutualAssuranceContract } from "./MutualAssuranceContract.sol";

/**
 * @title
 */
contract MutualAssuranceContractFactory {
    event ContractCreated(
        bytes32 indexed _commitment,
        address _contract,
        address[] _players
    );

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
            _players
        );

        /*
           for this to work, would need to pass in the station
           address to the mutual assurace contract

           uint256 length = _players.length;
           AttestationData[] memory a = new AttestationData[](length);
           for (uint256 i; i < length;) {
               a[i] = AttestationData({
                   about: _players[i],
                   key: _commitment,
                   val: hex"01"
               });
           }

           STATION.attest(a);
        */

        emit ContractCreated(
            _commitment,
            address(c),
            _players
        );
    }
}

