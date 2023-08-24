// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract Akolytes is ERC721 {

    address immutable MONS;
    address immutable SUDO_FACTORY;

    constructor(address _mons, address _factory) ERC721("Akolytes", "AKL") {
        MONS = _mons;
        SUDO_FACTORY = _factory;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}