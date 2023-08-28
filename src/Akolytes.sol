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
    error Akoless();

    uint256 constant MAX_AKOLS = 512;

    address immutable MONS;
    address immutable SUDO_FACTORY;
    address payable immutable public ROYALTY_HANDER;

    // Mapping of (token address, 160 bits | akolyte id, 96 bits) => amount already claimed for that id
    mapping(uint256 => uint256) public royaltyClaimedPerId;

    // Mapping of (akolyte id) => timestamp when unlocked
    mapping(uint256 => uint256) public unlockDatePerId;

    // Mapping of royalty amounts accumulated in total per royalty token
    mapping(address => uint256) public royaltyAccumulatedPerTokenType;

    constructor(address _mons, address _factory) ERC721("Akolytes", "AKL") {
        MONS = _mons;
        SUDO_FACTORY = _factory;
        ROYALTY_HANDER = payable(address(new RoyaltyHandler()));

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

    // Claims royalties accrued for owned IDs
    function claimRoyalties(address royaltyToken, uint256[] calldata ids) public returns (uint256) {
        uint256 idLength = ids.length;
        accumulateRoyalty(royaltyToken);
        uint256 amountToSend;
        uint256 amountPerId = royaltyAccumulatedPerTokenType[royaltyToken] / MAX_AKOLS;
        for (uint i; i < idLength; ++i) {
            if (ownerOf(ids[i]) == msg.sender) {
                uint256 idAndTokenKey = uint256(uint160(royaltyToken)) << 96 | ids[i];
                
                // This should undeflow if already claimed to the maximum amount
                uint256 royaltyToAdd = amountPerId - royaltyClaimedPerId[idAndTokenKey];

                // If we are sending a royalty amount, then keep track of the amount
                if (royaltyToAdd > 0) {
                    amountToSend += royaltyToAdd;
                    royaltyClaimedPerId[idAndTokenKey] = amountPerId;
                }
            }
            else {
                revert Akoless();
            }
        }
        // If native token
        if (royaltyToken == address(0)) {
            RoyaltyHandler(ROYALTY_HANDER).sendETH(payable(msg.sender), amountToSend);
        }
        // Otherwise, do ERC20 transfer
        else {
            RoyaltyHandler(ROYALTY_HANDER).sendERC20(msg.sender, royaltyToken, amountToSend);
        }
        return amountToSend;
    }

    // Accumulates royalties accrued
    function accumulateRoyalty(address royaltyToken) public {
        // Handle native token royalties
        if (royaltyToken == address(0)) {
            // Send balance and accumulate
            uint256 ethBalance = address(this).balance;
            royaltyAccumulatedPerTokenType[address(0)] += ethBalance;
            ROYALTY_HANDER.safeTransferETH(ethBalance);
        }
        else {
            uint256 tokenBalance = ERC20(royaltyToken).balanceOf(address(this));
            royaltyAccumulatedPerTokenType[royaltyToken] += tokenBalance;
            ERC20(royaltyToken).safeTransfer(ROYALTY_HANDER, tokenBalance);
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

    // Transfers and sets time delay if to/from a non-sudo pool
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        uint256 timestamp = block.timestamp;
        if (timestamp < unlockDatePerId[id]) {
            revert Cooldown();
        }
        if (!ILSSVMPairFactoryLike(SUDO_FACTORY).isValidPair(from) && !ILSSVMPairFactoryLike(SUDO_FACTORY).isValidPair(to)) {
            unlockDatePerId[id] = timestamp + 7 days;
        }
        super.transferFrom(from, to, id);
    }

    // Handles metadata from arweave hash
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }

    // Receive ETH
    receive() external payable {}
}