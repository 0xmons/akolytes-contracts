// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILSSVMPairFactoryLike {
    function isValidPair(address pairAddress) external view returns (bool);
}
