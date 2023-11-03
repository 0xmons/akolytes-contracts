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
        a = new Akolytes(
            0x30CAA3c54E12FB7b55D8eD8DbE10E3265c0a0020, // fake 0xmons
            0x967544b2Dd5c1c7A459e810C9B60AE4FC8227201, // the factory
            0x3d126031A109a93bC6D80F04Ba5684A0BdD9BE1b, // the markov
            0x5e9a0Ef66A6BC2E6Ac7C9811374521f7BAd89e53, // the curve
            0x9B2660A7BEcd0Bf3d90401D1C214d2CD36317da5, // the token
            0x9fe1E403c043214017a6719c1b64190c634229eF // the other curve
        );
        vm.stopBroadcast();
    }
}
