// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Markov} from "../src/Markov.sol";

contract MarkovTest is Test {
    Markov m;

    function setUp() public {
        m = new Markov();
    }

    event Foo(string s);
    function test_speak() public {
        string memory s = m.speak(1,200);
        emit Foo(s);
    }
}