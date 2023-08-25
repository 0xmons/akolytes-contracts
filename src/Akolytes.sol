// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactory.sol";

contract Akolytes is ERC721, ERC2981 {

    address immutable MONS;
    address immutable SUDO_FACTORY;

    // Mapping of (token address, 160 bits | id, 90 bits) => amount already claimed
    mapping(uint256 => uint256) public royaltyClaimedPerId;

    // Mapping of amount accumulated in total per token address
    mapping(address => uint256) public royaltyAccumulatedPerTokenType;

    constructor(address _mons, address _factory) ERC721("Akolytes", "AKL") {
        MONS = _mons;
        SUDO_FACTORY = _factory;

        // 1% royalty, set to this address
        _setDefaultRoyalty(address(this), 100);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
    }

    // Overrides both
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == type(IERC2981).interfaceId || // ERC165 interface for IERC2981
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}