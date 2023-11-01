// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721Enumerable {

    constructor() ERC721('A', 'A') {}

    function mint(uint256 offset, uint256 amount) public {
        for (uint i; i < amount; ++i) {
            _mint(msg.sender, offset + i);
        }
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}