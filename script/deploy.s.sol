// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Markov} from "../src/Markov.sol";
import {Akolytes} from "../src/Akolytes.sol";
import {Test20} from "../test/mocks/Test20.sol";

contract MyScript is Script {
    function run() external returns (Markov m, Test20 t, Akolytes a) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        m = new Markov();
        t = new Test20();
        a = new Akolytes(
            address(0),
            0x967544b2Dd5c1c7A459e810C9B60AE4FC8227201,
            address(m),
            0x5e9a0Ef66A6BC2E6Ac7C9811374521f7BAd89e53,
            address(t),
            0x9fe1E403c043214017a6719c1b64190c634229eF
        );
        vm.stopBroadcast();
    }
}
