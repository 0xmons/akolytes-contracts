// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ILSSVMPairFactoryLike} from "../../src/ILSSVMPairFactory.sol";

contract MockPairFactory is ILSSVMPairFactoryLike {

    mapping(address => bool) isAllowed;

    function whitelistAddy(address a) external {
        isAllowed[a] = true;
    }

    function isValidPair(address pairAddress) external view returns (bool) {
        if (isAllowed[pairAddress]) {
            return true;
        }
        else {
            return false;
        }
    }

}