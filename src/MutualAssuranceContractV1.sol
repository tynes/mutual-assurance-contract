// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
eth provides resources
- availability
- execution (congestion fees)
- state

contention - desire to get into a block a particular location
*/

import { Clone } from "clones-with-immutable-args/Clone.sol";
import { SafeProxyFactory } from "safe-contracts/proxies/SafeProxyFactory.sol";
import { SafeProxy } from "safe-contracts/proxies/SafeProxy.sol";
import { LibSort } from "solady/utils/LibSort.sol";

contract MutualAssuranceContractV1 is Clone {

    event Resolve(bool);

    /**
     * @notice Error when trying to resolve a contract that has already been
     *         resolved.
     */
    error Resolved();

    /**
     * @notice Reentrency error.
     */
    error Reentrant();

    /**
     * @notice Error when trying to resolve the contract too early.
     */
    error Early();

    bool internal _initialized;
    bool public resolved;
    uint256 internal _wall;
    uint256 public start;

    address[] public guardians;

    SafeProxyFactory public immutable safeFactory;
    GnosisSafe public immutable safeSingleton;

    function _commitment() internal pure returns (bytes32) {
        return bytes32(_getArgUint256(0));
    }

    function _duration() internal pure returns (uint256) {
        return _getArgUint256(32);
    }

    function _lump() internal pure returns (uint256) {
        return _getArgUint256(64);
    }

    function end() public view returns (uint256) {
        return _duration() + start;
    }

    function _guardians() internal returns ([]address) {
        address[] memory guardians = address[](_guardians.length);
        for (uint256 i; i < _guardians.length; i++) {
            guardians[i] = _guardians[i];
        }
        return guardians;
    }

    constructor(SafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) {
        safeFactory = _safeFactory;
        safeSingleton = _safeSingleton;
    }

    /**
     * @notice Responsible for setting the storage that the contract needs to function.
     *         This should be called by the factory directly after being deployed.
     */
    function initialize(
        address[] memory _guardians
    ) public {
        require(_initialized == false);

        LibSort.sort(_guardians);

        uint256 length = _guardians.length;
        require(length > 0);
        unchecked {
            for (uint256 i; i < length; i++) {
                guardians.push(_guardians[i]);
            }
        }

        start = block.timestamp;
        _initialized = true;
        _wall = 1;
    }

    /**
     * @notice prevent reentrency
     */
    modifier nonreentrant() {
        if (_wall == 0) revert Reentrant();
        _wall = 0;
        _;
        _wall = 1;
    }

    /**
     * @notice Public getter that lets the user know if the contract is
     *         resolvable.
     */
    function resolvable() public view returns (bool) {
        return block.timestamp >= end();
    }

    /**
     * @notice Call this to resolve the mutual assurance contract.
     */
    function resolve() external nonreentrant {
        // ensure it can only be resolved once
        if (resolved) revert Resolved();

        // ensure enough time has passed
        if (!resolvable()) revert Early();

        // effects then interactions
        resolved = true;

        // ensure that enough money was collected
        bool success = address(this).balance >= _lump();

        if (success) win();
        else lose();

        emit Resolve(success);
    }

    /**
     * @notice
     */
    function win() internal {
        /*
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
        */

        bytes memory initialize = abi.encodeCall(
            GnosisSafe.setup,
            (
                _guardians(),    // owners
                0,               // threshold
                address(0)       // to
                hex"",           // data
                address(0),      // fallbackHandler
                address(0),      // paymentToken
                0                // payment
                address(0)       // paymentReceiver
            )
        );

        SafeProxy proxy = safeFactory.deployProxy({
            _singleton: safeSingleton,
            initializer: initialize,
            salt: bytes32(0)
        });

        // deploy a gnosis safe with the guardians as the owners
        // transfer the money there
        // setupOwners
    }

    /**
     * @notice
     */
    function lose() internal {
        // send the money back
    }

    receive() external payable {}
}
