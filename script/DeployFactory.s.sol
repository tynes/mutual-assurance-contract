// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { GnosisSafeProxyFactory } from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "safe-contracts/GnosisSafe.sol";
import { PactFactory } from "../src/PactFactory.sol";
import { Pact } from "../src/Pact.sol";

/// @notice
contract DeployFactory is Script {
    /// @notice
    error UnknownChain(uint256);

    /// @notice
    error NoCode(string, address);

    /// @notice
    struct SafeAddresses {
        GnosisSafeProxyFactory factory;
        GnosisSafe singleton;
    }

    /// @notice
    function run() public returns (address) {
        SafeAddresses memory addrs = getSafeAddresses();
        return _run(addrs.factory, addrs.singleton);
    }

    /// @notice
    function run(GnosisSafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) public returns (address) {
        return _run(_safeFactory, _safeSingleton);
    }

    /// @notice
    function _run(GnosisSafeProxyFactory _safeFactory, GnosisSafe _safeSingleton) internal returns (address) {
        if (address(_safeFactory).code.length == 0) revert NoCode("GnosisSafeProxyFactory", address(_safeFactory));
        if (address(_safeSingleton).code.length == 0) revert NoCode("GnosisSafe", address(_safeSingleton));

        Pact getter = new Pact({
            _safeFactory: _safeFactory,
            _safeSingleton: _safeSingleton
        });

        string memory version = getter.version();
        bytes32 salt = keccak256(bytes(version));

        console.log("create2 salt:", vm.toString(salt));

        vm.broadcast();
        PactFactory factory = new PactFactory{ salt: salt }({
            _safeFactory: _safeFactory,
            _safeSingleton: _safeSingleton
        });

        Pact pact = factory.pact();

        console.log("factory address:", address(factory));
        console.log("factory version:", factory.version());
        console.log("pact singleton address:", address(pact));
        console.log("pact version:", pact.version());
        return address(factory);
    }

    /// @notice
    function getSafeAddresses() internal returns (SafeAddresses memory) {
        uint256 chainid = block.chainid;
        address factory;
        address singleton;

        if (chainid == 1) {
            factory = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
            singleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;
        } else if (chainid == 5) {
            factory = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
            singleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;
        } else if (chainid == 10) {
            factory = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC;
            singleton = 0x69f4D1788e39c87893C980c06EdF4b7f686e2938;
        } else if (chainid == 420) {
            factory = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC;
            singleton = 0x69f4D1788e39c87893C980c06EdF4b7f686e2938;
        } else if (chainid == 31337) {
            factory = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
            singleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;
            vm.etch(factory, vm.getDeployedCode("GnosisSafeProxyFactory.sol"));
            vm.etch(singleton, vm.getDeployedCode("GnosisSafe.sol"));
        } else {
            revert UnknownChain(chainid);
        }

        return SafeAddresses({
            factory: GnosisSafeProxyFactory(factory),
            singleton: GnosisSafe(payable(singleton))
        });
    }
}
