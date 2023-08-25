// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract Akolytes is ERC721, ERC2981 {

    address immutable MONS;
    address immutable SUDO_FACTORY;

    // Mapping of (token address | id) => amount claimed
    mapping(uint256 => uint256) public royaltyClaimedPerId;

    // Mapping of amount accumulated in total per token address
    mapping(address => uint256) public royaltyAccumulatedPerTokenType;

    constructor(address _mons, address _factory) ERC721("Akolytes", "AKL") {
        MONS = _mons;
        SUDO_FACTORY = _factory;

        // 1% royalty, set to this address
        _setDefaultRoyalty(address(this), 100);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}