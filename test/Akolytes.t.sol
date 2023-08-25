// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Akolytes} from "../src/Akolytes.sol";
import {RoyaltyHandler} from "../src/RoyaltyHandler.sol";

contract MaliciousCaller is Test {

    Akolytes akolytes;

    function setUp() public {
        akolytes = new Akolytes(address(0), address(0));
    }

    function test_royaltyHandlerOwnerIsAkolytes() public {
        assertEq(RoyaltyHandler(akolytes.ROYALTY_HANDER()).owner(), address(akolytes));
    }
}