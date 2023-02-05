// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAttestationStation } from "./IAttestationStation.sol";
import { SafeCall } from "./SafeCall.sol";

/**
 * @title  MutualAssuranceContract
 * @author tynes
 * @author Optimism Collective
 * @notice Enter into a mutual assurance contract with a set of players.
 *         Players can send ether to this contract and if enough ether is
 *         accumulated into the contract by the timeout, then the contract
 *         resolves to a win and the ether is forwarded to a chosen account.
 *         If not enough ether is accumulated, then the ether is returned to
 *         the participants.
 */
contract MutualAssuranceContract {
    /**
     * @notice Error when trying to resolve the contract too early.
     */
    error TooEarly();

    /**
     * @notice Error when sending from this contract reverts.
     */
    error PleaseAccept(address);

    /**
     * @notice Error when a player that isn't on the set of allowed participants
     *         attempts to send ether to the contract.
     */
    error NotAllowed(address);

    /**
     * @notice Error when trying to resolve a contract that has already been
     *         resolved.
     */
    error AlreadyResolved();

    /**
     * @notice Reentrency error.
     */
    error NonReentrant();

    /**
     * @notice A contribution to the mutual assurance contract.
     */
    struct Contribution {
        address from;
        uint256 amount;
    }

    /**
     * @notice An event for when a player contributes.
     */
    event Assurance(address who, uint256 value);

    /**
     * @notice An event for when the contract resolves.
     */
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
     * @notice A handle to the factory that deployed this contract.
     */
    address immutable public FACTORY;

    /**
     * @notice The address of the recipient when the contract resolves
     *         to the winning direction.
     */
    address immutable public COMMANDER;

    /**
     * @notice A handle to the attestation station.
     */
    IAttestationStation immutable public STATION;

    /**
     * @notice A topic for the AttestationStation. Need better management of
     *         these.
     */
    bytes32 constant public TOPIC = bytes32("MutualAssuranceContractV0");

    /**
     * @notice A public getter for the resolution state of the contract.
     */
    bool public resolved;

    /**
     * @notice The set of contributions.
     */
    Contribution[] public contributions;

    /**
     * @notice Used for reentrency lock
     */
    uint256 internal wall;

    /**
     * @notice
     */
    constructor(
        bytes32 _commitment,
        uint256 _duration,
        uint256 _lump,
        address _commander,
        address _station,
        address[] memory _players
    ) {
        COMMITMENT = _commitment;
        END = block.timestamp + _duration;
        LUMP = _lump;
        COMMANDER = _commander;
        FACTORY = msg.sender;
        STATION = IAttestationStation(_station);
        wall = 1;

        uint256 length = _players.length;
        IAttestationStation.AttestationData[] memory a = new IAttestationStation.AttestationData[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                a[i] = IAttestationStation.AttestationData({
                    about: _players[i],
                    key: bytes32("player"),
                    val: hex"01"
                });
            }
        }

        STATION.attest(a);
    }

    /**
     * @notice prevent reentrency
     */
    modifier nonreentrant() {
        if (wall == 0) {
            revert NonReentrant();
        }
        wall = 0;
        _;
        wall = 1;
    }

    /**
     * @notice Getter to see if a player is allowed to participate in this
     *         mutual assurance contract.
     */
    function isAllowed(address who) public view returns (bool) {
        bytes memory a = STATION.attestations(address(this), who, bytes32("player"));
        return a.length != 0;
    }

    /**
     * @notice Public getter that lets the user know if the contract is
     *         resolvable.
     */
    function isResolvable() external view returns (bool) {
        return block.timestamp >= END;
    }

    /**
     * @notice Call this to resolve the mutual assurance contract.
     */
    function resolve() external nonreentrant {
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

        STATION.attest(FACTORY, bytes32("MutualAssuranceContractV0_Result"), abi.encode(success));

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
        if (resolved) {
            revert AlreadyResolved();
        }

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

        // make an attestation. update the value in the station
        bytes memory a = STATION.attestations(address(this), sender, TOPIC);
        if (a.length == 0) {
            STATION.attest(sender, TOPIC, abi.encode(value));
        } else {
            uint256 total = abi.decode(a, (uint256));
            STATION.attest(sender, TOPIC, abi.encode(value + total));
        }

        // emit an event indicating a participant contributed
        emit Assurance(sender, value);
    }
}
