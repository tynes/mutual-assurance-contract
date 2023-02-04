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
    error BadAccount(address);

    /**
     * @notice
     */
    error ContractNonExistent(address, bytes32);

    /**
     * @notice
     */
    error NoPlayers();

    /**
     * @notice
     */
    IAttestationStation public immutable STATION;

    /**
     * @notice
     */
    event ContractCreated(
        bytes32 indexed _commitment,
        address indexed _contract,
        address[] _players
    );

    bytes32 constant public TOPIC = bytes32("players");

    /**
     * @notice
     */
    constructor(address _station) {
        STATION = IAttestationStation(_station);
    }

    /**
     * @notice
     */
    function deploy(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address[] memory _players
    ) public returns (address) {
        MutualAssuranceContract c = new MutualAssuranceContract(
            _commitment,
            _duration,
            _lump,
            _commander,
            address(STATION)
        );

        uint256 length = _players.length;
        if (length == 0) {
            revert NoPlayers();
        }

        IAttestationStation.AttestationData[] memory a = new IAttestationStation.AttestationData[](length + 1);

        unchecked {
            for (uint256 i; i < length; ++i) {
                // Prevent the mutual assurace contract from
                // playing itself.
                if (_players[i] == address(c)) {
                    revert BadAccount(_players[i]);
                }

                a[i] = IAttestationStation.AttestationData({
                    about: _players[i],
                    key: _commitment,
                    val: abi.encode(address(c))
                });
            }
        }

        a[length] = IAttestationStation.AttestationData({
            about: address(c),
            key: TOPIC,
            val: abi.encode(_players)
        });

        STATION.attest(a);

        emit ContractCreated(_commitment, address(c), _players);

        return address(c);
    }

    /**
     * @notice
     */
    function get(
        address _player,
        bytes32 _commitment
    ) public view returns (address) {
        bytes memory a = STATION.attestations(address(this), _player, _commitment);
        if (a.length == 0) {
            revert ContractNonExistent(_player, _commitment);
        }
        return abi.decode(a, (address));
    }

    /**
     * @notice
     */
    function players(address _contract) public view returns (address[] memory) {
        bytes memory a = STATION.attestations(address(this), _contract, bytes32("players"));
        if (a.length == 0) {
            return new address[](0);
        } else {
            return abi.decode(a, (address[]));
        }
    }

    /**
     * @notice
     */
    function commitment(string memory _c) public pure returns (bytes32) {
        return keccak256(bytes(_c));
    }
}
