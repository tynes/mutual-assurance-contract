// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Interface for the AttestationStation
 * @author Optimism Collective
 */
interface IAttestationStation {
    /**
     * @notice Emits when an attestation is created
     */
    event AttestationCreated(
        address indexed creator,
        address indexed about,
        bytes32 indexed key,
        bytes val
    );

    /**
     * @notice The structure of an attestation
     */
    struct AttestationData {
        address about;
        bytes32 key;
        bytes val;
    }

    /**
     * @notice Fetch attestation data
     */
    function attestations(address, address, bytes32) external view returns (bytes memory);

    /**
     * @notice Create multiple attestations with a single call
     */
    function attest(AttestationData[] memory _attestations) external;

    /**
     * @notice Create a single attestation
     */
    function attest(address _about, bytes32 _key, bytes memory val) external;
}
