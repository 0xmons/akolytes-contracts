// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract RoyaltyHandler is Owned {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    constructor() Owned(msg.sender) {}
}