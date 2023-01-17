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
     * @notice The address of the recipient when the contract resolves
     *         to the winning direction.
     */
    address immutable public COMMANDER;

    /**
     * @notice
     */
    bool public resolved;

    /**
     * @notice
     */
    uint256 public pot;

    /**
     * @notice
     */
    mapping(address => uint256) public wills;

    /**
     * @notice
     */
    mapping(address => bool) private players;

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
        address[] memory _players
    ) {
        COMMITMENT = _commitment;
        END = block.timestamp + _duration;
        LUMP = _lump;
        COMMANDER = _commander;

        // i don't really like this hmm
        uint256 length = _players.length;
        for (uint256 i; i < length;) {
            players[_players[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     *
     * TODO: i'd like to turn this into a call to the attestation station
     */
    function isAllowed(address who) public view returns (bool) {
        /*
        // Have the factory make the attestations

        bytes memory a = ATTESTATION_STATION.attestations(
            address(factory),
            who,
            COMMITMENT
        );

        return keccak256(a) == keccak256(hex"01")
        */

        return players[who];
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

        // ensure that enough money was collected
        if (pot < LUMP) {
            lose();
        } else {
            win();
        }

        // it has been resolved
        resolved = true;
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
        for (uint256 i; i < length; ) {
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

            unchecked {
                ++i;
            }
        }
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
            pot,
            hex""
        );

        if (success == false) {
            revert PleaseAccept(COMMANDER);
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

        // keep track of how much the sender has contributed
        wills[sender] += value;

        // keep track of the total amount of contributions
        pot += value;

        // store the contribution in an array so that
        // it can be refunded if the contract resolves in
        // the losing direction
        contributions.push(Contribution(sender, value));
    }
}
