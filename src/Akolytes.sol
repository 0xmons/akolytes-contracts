// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactory.sol";
import {RoyaltyHandler} from "./RoyaltyHandler.sol";
import {ERC721} from "./ERC721.sol";

import {strings} from "./libs/strings.sol";
import {Base64} from "./libs/Base64.sol";
import {Distributions} from "./libs/Distributions.sol";

contract Akolytes is ERC721, ERC2981 {

    struct OwnerOfWithData {
        address owner;
        uint96 lastTransferTimestamp;
    }

    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using strings for string;
    using strings for strings.slice;

    error Cooldown();
    error Monless();
    error Akoless();

    uint256 constant MAX_AKOLS = 512;
    string private constant ARWEAVE_HASH = "XxDgZs6LRWDmzQIfR0Lssic8a4k3eQbyaosttObj7Ec";

    // Name generation process: 1 random from s1, 1 random from s2, and then 0-2 from s3
    string private constant s1 =
        "Cth,Az,Ap,Ch,Bl,Gh,Gl,Kr,M,Nl,Ny,D,Xy,Rh,U,Bl,Cz,En,Fz,H,Il,J,Jh,Y,YvK,Z,Zh,Sl,T,O,U,Ub,Os,Eh,Sh";
    uint256 private constant s1Length = 35;

    string private constant s2 =
        "ak,al,es,et,id,il,id,oo,or,ux,un,ap,ek,ex,in,ol,up,-af,-aw,'et,'ed,-in,-is,'od,-at,-of";
    uint256 private constant s2Length = 26;

    string private constant s3 =
        "ag,al,on,ak,ash,a,ber,bal,buk,cla,ced,ck,dar,dru,est,end,fli,fa,-fur,gen,ga,his,ha,ilk,in,-in,ju,ja,-ki,ll,lo,mo,-mu,ma,no,r,ss,sh,sto,ta,tha,un,vy,va,wy,wu,y,yy,z,zs,ton,gon,-man,lu,get,har,uz,ek,ec,-s";
    uint256 private constant s3Length = 60;

    // Max number of times we grab a syllable from s3
    uint256 private constant maxS3Iters = 2;

    // Immutable contract reference vars
    address immutable MONS;
    address immutable SUDO_FACTORY;
    address payable immutable public ROYALTY_HANDER;

    // Mapping of (id, 256 bits) => (owner address, 160 bits | unlockDate timestamp, 96 bits)
    mapping(uint256 => OwnerOfWithData) public ownerOfWithData;

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

    function getName(uint256 seed) public pure returns (string memory) {
        uint256 rng = seed;
        // Get uniform from s1
        string memory nameS1 = getItemFromCSV(s1, rng % s1Length);
        // Update seed
        rng = uint256(keccak256(abi.encode(rng)));
        // Get uniform from s2
        string memory nameS2 = getItemFromCSV(s2, rng % s2Length);
        // Concatenate the two
        string memory name = string(abi.encodePacked(nameS1, nameS2));
        // Update seed
        rng = uint256(keccak256(abi.encode(rng)));
        // Add any s3 syllables (if possible)
        for (uint256 i = 0; i < rng % (maxS3Iters + 1); i++) {
            string memory nameS3 = getItemFromCSV(s3, rng % s3Length);
            rng = uint256(keccak256(abi.encode(rng)));
            name = string(abi.encodePacked(name, nameS3));
        }
        return name;
    }

    // Don't worry about anything from here until the tokenURI
    function getItemFromCSV(string memory str, uint256 index)
        internal
        pure
        returns (string memory)
    {
        strings.slice memory strSlice = str.toSlice();
        string memory separatorStr = ",";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }
    function d1(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d1(seed));
    }
    function d2(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d2(seed));
    }
    function d3(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d3(seed));
    }
    function d4(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d4(seed));
    }
    function d5(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d5(seed));
    }
    function d6(uint256 seed) internal view returns (string memory) {
      return Strings.toString(Distributions.d6(seed));
    }
    function secondD(uint256 seed, uint256 id) internal view returns (string memory) {
      return string(abi.encodePacked(
            '"trait_type": "4tiart",'
            '"value": "', d4(seed),
          '"},{', 
            '"trait_type": "V",'
            '"value": "', d5(seed),
          '"},{', 
            '"trait_type": "-- . . . .",'
            '"value": "', d6(id),
          '"}'
      ));
    }
    function getD(uint256 seed, uint256 id) internal view returns (string memory) {
          return string(abi.encodePacked('{', 
            '"trait_type": "TRAIT ONE",'
            '"value": "', d1(seed),
          '"},{', 
            '"trait_type": "7R417_2",'
            '"value": "', d2(seed),
          '"},{', 
            '"trait_type": "trait3",'
            '"value": "', d3(seed),
          '"},{', 
            secondD(seed, id)));
    }

    // Handles metadata from arweave hash, constructs name and metadata
    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encode(id & uint160(SUDO_FACTORY))));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                getName(id),
                                '", "description":"',
                                '", "image": "',
                                "ar://",
                                ARWEAVE_HASH,
                                "/m1",
                                Strings.toString(id),
                                ".gif",
                                '", "attributes": [',
                                  getD(seed, id),
                                  ']',
                                '}'
                            )
                        )
                    )
                )
            );
    }

    // Receive ETH
    receive() external payable {}
}