// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAttestationStation } from "./IAttestationStation.sol";
import { MutualAssuranceContract } from "./MutualAssuranceContract.sol";

/**
 * @title  MutualAssuranceContractFactory
 * @notice A factory contract for entering mutual assurace contracts.
 */
contract MutualAssuranceContractFactory {
    /**
     * @notice Prevent entering mutual assurace contracts with bad accounts.
     */
    error BadAccount(address);

    /**
     * @notice Error for querying a mutual assurace contract that does not
     *         exist.
     */
    error ContractNonExistent(address, bytes32);

    /**
     * @notice There must at least 1 player in the mutual assurace contract.
     */
    error NoPlayers();

    /**
     * @notice A reference to the AttestationStation.
     */
    IAttestationStation public immutable STATION;

    /**
     * @notice Emits when a mutual assurace contract is created so its easy to
     *         track.
     */
    event ContractCreated(
        bytes32 indexed _commitment,
        address indexed _contract,
        address[] _players
    );

    /**
     * @notice The AttestationStation topic used by this contract to make it
     *         easy to know what players are in a mutual assurace contract.
     */
    bytes32 constant public TOPIC = bytes32("players");

    /**
     * @notice Set the AttestationStation in the constructor as an immutable.
     */
    constructor(address _station) {
        STATION = IAttestationStation(_station);
    }

    /**
     * @notice Create a mutual assurace contract.
     * @param  _commitment A commitment to the purpose the contract was entered.
     *                     Can be a bytes32 wrapped string or a hash of a longer
     *                     string.
     * @param  _duration   The length of the mutual assurace contract.
     * @param  _lump       The length of the mutual assurace contract.
     * @param  _commander  The recipient of the funds of when the mutual
     *                     assurace contract resolves to a win.
     * @param  _players    The participants in the mutual assurace contract.
     */
    function deploy(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address[] memory _players
    ) public returns (address) {
        if (_players.length == 0) {
            revert NoPlayers();
        }

        MutualAssuranceContract c = new MutualAssuranceContract(
            _commitment,
            _duration,
            _lump,
            _commander,
            address(STATION),
            _players
        );

        STATION.attest(address(c), TOPIC, abi.encode(_players));
        emit ContractCreated(_commitment, address(c), _players);

        return address(c);
    }

    /**
     * @notice
     */
    function players(address _contract) public view returns (address[] memory) {
        bytes memory a = STATION.attestations(address(this), _contract, TOPIC);
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
