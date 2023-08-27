// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721('A', 'A') {}

    function mint(uint256 offset, uint256 amount) public {
        for (uint i; i < amount; ++i) {
            _mint(msg.sender, offset + i);
        }
    }

    // Handles metadata from arweave hash
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}