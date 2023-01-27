// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAttestationStation } from "./IAttestationStation.sol";
import { SafeCall } from "./SafeCall.sol";

/**
 * @title
 */
contract MutualAssuranceContract {
    /**
     * @notice
     */
    error TooEarly();

    /**
     * @notice
     */
    error PleaseAccept(address);

    /**
     * @notice
     */
    error NotAllowed(address);

    /**
     * @notice
     */
    error AlreadyResolved();

    /**
     * @notice
     */
    struct Contribution {
        address from;
        uint256 amount;
    }

    event Assurance(address who, uint256 value);

    event Resolved(bool);

    /**
     * @notice A commitment to a shared cause of collaboration.
     */
    bytes32 immutable public COMMITMENT;

    /**
     * @notice The total amount of value that must be accumulated
     *         for the contract to resolve in the winning direction.
     */
    uint256 immutable public LUMP;

    /**
     * @notice The timetamp of the end of the mutual assurace contract.
     */
    uint256 immutable public END;

    /**
     *
     */
    address immutable public FACTORY;

    /**
     * @notice The address of the recipient when the contract resolves
     *         to the winning direction.
     */
    address immutable public COMMANDER;

    /**
     * @notice
     */
    IAttestationStation immutable STATION;

    bytes32 constant public TOPIC = bytes32("MutualAssuranceContractV0");

    /**
     * @notice
     */
    bool public resolved;

    /**
     * @notice
     */
    Contribution[] public contributions;

    /**
     * @notice
     */
    constructor(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address _station
    ) {
        COMMITMENT = _commitment;
        END = block.timestamp + _duration;
        LUMP = _lump;
        COMMANDER = _commander;
        FACTORY = msg.sender;
        STATION = IAttestationStation(_station);
    }

    /**
     * @notice
     */
    function isAllowed(address who) public view returns (bool) {
        bytes memory a = STATION.attestations(address(FACTORY), who, COMMITMENT);
        return a.length != 0;
    }

    /**
     * @notice
     */
    function resolve() external {
        // ensure it can only be resolved once
        if (resolved) {
            revert AlreadyResolved();
        }

        // ensure enough time has passed
        if (block.timestamp < END) {
            revert TooEarly();
        }

        uint256 pot = address(this).balance;

        // ensure that enough money was collected
        bool success = pot >= LUMP;

        if (success) {
            win();
        } else {
            lose();
        }

        STATION.attest(FACTORY, TOPIC, abi.encode(success));

        // it has been resolved
        resolved = true;

        emit Resolved(success);
    }

    /**
     * @notice `win` is called when the mutual assurance contract has enough
     *         value in it when the contract resolves.
     *         It will send the value to the `COMMANDER`.
     */
    function win() internal {
        bool success = SafeCall.call(
            COMMANDER,
            gasleft(),
            address(this).balance,
            hex""
        );

        if (success == false) {
            revert PleaseAccept(COMMANDER);
        }

        uint256 length = contributions.length;
        IAttestationStation.AttestationData[] memory a = new IAttestationStation.AttestationData[](length);

        unchecked {
            for (uint256 i; i < length; ++i) {
                Contribution memory c = contributions[i];

                a[i] = IAttestationStation.AttestationData({
                    about: c.from,
                    key: TOPIC,
                    val: abi.encode(c.amount)
                });

            }
        }

        STATION.attest(a);
    }

    /**
     * @notice `lose` is called when the mutual assurance contract
     *         has less value in it when the contract resolves than
     *         what is required to `win`.
     *         This assumes that contributors are not malicious as it
     *         is possible for contributors to prevent money from being
     *         withdrawn here by reverting.
     *         This contract could be hardened in the future to make it
     *         safer to interact with untrusted accounts.
     */
    function lose() internal {
        uint256 length = contributions.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                Contribution memory c = contributions[i];

                bool success = SafeCall.call(
                    c.from,
                    gasleft(),
                    c.amount,
                    hex""
                );

                if (success == false) {
                    revert PleaseAccept(c.from);
                }
            }
        }
    }

    /**
     * @notice Allowed senders can submit ether to the contract.
     *         If value is accrued into this contract via alternative
     *         methods, it will be stuck.
     */
    receive() external payable {
        address sender = msg.sender;
        uint256 value = msg.value;

        // ensure that the sender is allowed to contribute
        if (isAllowed(sender) == false) {
            revert NotAllowed(sender);
        }

        // store the contribution in an array so that
        // it can be refunded if the contract resolves in
        // the losing direction
        contributions.push(Contribution(sender, value));

        emit Assurance(sender, value);
    }
}
