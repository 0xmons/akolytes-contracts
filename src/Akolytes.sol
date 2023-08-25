// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactory.sol";
import {RoyaltyHandler} from "./RoyaltyHandler.sol";

contract Akolytes is ERC721, ERC2981 {

    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    error Cooldown();
    error Monless();

    address immutable MONS;
    address immutable SUDO_FACTORY;
    address immutable public ROYALTY_HANDER;

    // Mapping of (token address, 160 bits | akolyte id, 96 bits) => amount already claimed for that id
    mapping(uint256 => uint256) public royaltyClaimedPerId;

    // Mapping of (akolyte id) => timestamp when unlocked
    mapping(uint256 => uint256) public unlockDatePerId;

    // Mapping of royalty amount accumulated in total per royalty token
    mapping(address => uint256) public royaltyAccumulatedPerTokenType;

    constructor(address _mons, address _factory) ERC721("Akolytes", "AKL") {
        MONS = _mons;
        SUDO_FACTORY = _factory;
        ROYALTY_HANDER = address(new RoyaltyHandler());

        // 5% royalty, set to this address
        _setDefaultRoyalty(address(this), 500);
    }

    // Claim for mons
    function claimForMons(uint256[] calldata ids) public {
        for (uint i; i < ids.length; ++i) {
            if (ERC721(MONS).ownerOf(ids[i]) == msg.sender) {
                _mint(msg.sender, ids[i]);
            }
            else {
                revert Monless();
            }
        }
    }

    // Overrides both ERC721 and ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == type(IERC2981).interfaceId || // ERC165 interface for IERC2981
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        uint256 timestamp = block.timestamp;
        if (timestamp < unlockDatePerId[id]) {
            revert Cooldown();
        }
        if (!ILSSVMPairFactoryLike(SUDO_FACTORY).isValidPair(from) && ILSSVMPairFactoryLike(SUDO_FACTORY).isValidPair(to)) {
            unlockDatePerId[id] = timestamp + 7 days;
        }
        super.transferFrom(from, to, id);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}