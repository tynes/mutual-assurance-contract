// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title
 */
interface IAttestationStation {
    /**
     * @notice
     */
    struct AttestationData {
        address about;
        bytes32 key;
        bytes val;
    }

    /**
     * @notice
     */
    function attestations(address, address, bytes32) external view returns (bytes memory);

    /**
     * @notice
     */
    function attest(AttestationData[] memory _attestations) external;

    /**
     * @notice
     */
    function attest(address _about, bytes32 _key, bytes memory val) external;
}
