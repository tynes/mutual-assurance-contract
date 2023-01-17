// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title
 */
interface IAttestationStation {
    struct AttestationData {
        address about;
        bytes32 key;
        bytes val;
    }

    /**
     * @notice
     */
    function attestations(address, address, bytes32) external returns (bytes memory);

    /**
     * @notice
     */
    function attest(AttestationData[] memory _attestations) external;
}
