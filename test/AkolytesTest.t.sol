// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockPairFactory} from "./mocks/MockPairFactory.sol";
import {Akolytes} from "../src/Akolytes.sol";
import {Markov} from "../src/Markov.sol";
import {RoyaltyHandler} from "../src/RoyaltyHandler.sol";

// Sudo specific imports
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LSSVMPairFactory} from "lib/lssvm2/src/LSSVMPairFactory.sol";
import {RoyaltyEngine} from "lib/lssvm2/src/RoyaltyEngine.sol";
import {LSSVMPairERC721ETH} from "lib/lssvm2/src/erc721/LSSVMPairERC721ETH.sol";
import {LSSVMPairERC1155ETH} from "lib/lssvm2/src/erc1155/LSSVMPairERC1155ETH.sol";
import {LSSVMPairERC721ERC20} from "lib/lssvm2/src/erc721/LSSVMPairERC721ERC20.sol";
import {LSSVMPairERC1155ERC20} from "lib/lssvm2/src/erc1155/LSSVMPairERC1155ERC20.sol";
import {LSSVMPair} from "lib/lssvm2/src/LSSVMPair.sol";
import {LinearCurve} from "lib/lssvm2/src/bonding-curves/LinearCurve.sol";
import {GDACurve} from "lib/lssvm2/src/bonding-curves/GDACurve.sol";
import {ICurve} from "lib/lssvm2/src/bonding-curves/ICurve.sol";

contract AkolytesTest is Test {

    using SafeTransferLib for address payable;

    Akolytes akolytes;
    MockERC721 mockMons;
    MockPairFactory mockPairFactory;
    LSSVMPairFactory pairFactory;
    LinearCurve linearCurve;
    GDACurve gdaCurve;

    address payable constant ALICE = payable(address(123456789));
    address payable constant BOB = payable(address(999999999));

    function setUp() public {
        mockMons = new MockERC721();
        mockPairFactory = new MockPairFactory();
        akolytes = new Akolytes(address(mockMons), address(mockPairFactory), address(0), address(0), address(0), address(0));
        
        // Initialize sudo stuff
        RoyaltyEngine royaltyEngine = new RoyaltyEngine(address(0)); // We use a fake registry
        LSSVMPairERC721ETH erc721ETHTemplate = new LSSVMPairERC721ETH(royaltyEngine);
        LSSVMPairERC721ERC20 erc721ERC20Template = new LSSVMPairERC721ERC20(royaltyEngine);
        LSSVMPairERC1155ETH erc1155ETHTemplate = new LSSVMPairERC1155ETH(royaltyEngine);
        LSSVMPairERC1155ERC20 erc1155ERC20Template = new LSSVMPairERC1155ERC20(royaltyEngine);
        pairFactory = new LSSVMPairFactory(
            erc721ETHTemplate,
            erc721ERC20Template,
            erc1155ETHTemplate,
            erc1155ERC20Template,
            payable(address(0)),
            0, // Zero protocol fee to make calculations easier
            address(this)
        );
        linearCurve = new LinearCurve();
        gdaCurve = new GDACurve();
        pairFactory.setBondingCurveAllowed(ICurve(address(linearCurve)), true);
        pairFactory.setBondingCurveAllowed(ICurve(address(gdaCurve)), true);
    }

    function test_tap_to_acquire_akolyte() public {

        // Mint IDs 0 to 9 to msg.sender
        mockMons.mint(0, 10);
        uint256[] memory ids = new uint256[](10);

        // Attempt to claim for IDs 0 to 9
        for (uint i; i < 10; ++i) {
            ids[i] = i;
        }
        akolytes.tap_to_acquire_akolyte(ids);

        // Assert that we own them all
        for (uint i; i < 10; ++i) {
            assertEq(akolytes.ownerOf(i), address(this));
        }

        // Assert that msg.sender has 10
        assertEq(akolytes.balanceOf(address(this)), 10);

        // Assert that we cannot claim again
        vm.expectRevert("ALREADY_MINTED");
        akolytes.tap_to_acquire_akolyte(ids);

        // Attempt to claim for ALICE, expect it to fail
        vm.prank(ALICE);
        vm.expectRevert(Akolytes.Monless.selector);
        akolytes.tap_to_acquire_akolyte(ids);

        // Mint another one for ALICE to cliam
        vm.startPrank(ALICE);
        mockMons.mint(10, 1);
        uint256[] memory aliceId = new uint256[](1);
        aliceId[0] = 10;
        akolytes.tap_to_acquire_akolyte(aliceId);
        assertEq(akolytes.balanceOf(address(ALICE)), 1);
        assertEq(akolytes.ownerOf(10), address(ALICE));
        vm.stopPrank();
    }

    function test_tap_to_acquire_akolyteMalicious() public {
        // Mint IDs 0 to 9 to msg.sender
        mockMons.mint(0, 10);
        uint256[] memory ids = new uint256[](10);

        // Attempt to claim for ID #0 ten times
        vm.expectRevert("ALREADY_MINTED");
        akolytes.tap_to_acquire_akolyte(ids);

        // Mint ID 1000 to msg.sender
        mockMons.mint(1000, 1);
        ids = new uint256[](1);
        ids[0] = 1000;

        // Expect it to fail because it is greater than ID 512
        vm.expectRevert(Akolytes.Scarce.selector);
        akolytes.tap_to_acquire_akolyte(ids);
    }

    function test_yeet() public {

        uint256[] memory ids = new uint256[](1);
        ids[0] = 341;

        // ALICE cannot yeet
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(ALICE);
        akolytes.yeet(ids);

        // msg.sender cannot yet
        vm.expectRevert(Akolytes.NoYeet.selector);
        akolytes.yeet(ids);

        // Wait 7 days and then attempt to yeet
        // Should fail because ID is too high
        vm.warp(block.timestamp + 7 days + 1);
        vm.expectRevert(Akolytes.Scarce.selector);
        akolytes.yeet(ids);

        // Try again with lower ID
        // It should
        ids[0] = 340;
        akolytes.yeet(ids);
        assertEq(akolytes.balanceOf(address(this)), 1);
    }

    function test_adjustRoyalty() public {

        // ALICE cannot adjust
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(ALICE);
        akolytes.adjustRoyalty(0);

        // Caller can adjust
        akolytes.adjustRoyalty(0);
        akolytes.adjustRoyalty(1000);

        // Caller cannot adjust past max
        vm.expectRevert(Akolytes.TooHigh.selector);
        akolytes.adjustRoyalty(1001);
    }

    function test_transferLock() public {

        // Mint ID 0 to msg.sender
        // Attempt to claim for ID 0
        mockMons.mint(0, 1);
        uint256[] memory ids = new uint256[](1);
        akolytes.tap_to_acquire_akolyte(ids);

        // Transfer to ALICE
        address testAddy = address(this);
        akolytes.transferFrom(testAddy, ALICE, 0);

        // Cannot transfer back from ALICE because of cooldown
        vm.prank(ALICE);
        vm.expectRevert(Akolytes.Cooldown.selector);
        akolytes.transferFrom(ALICE, testAddy, 0);

        // Advance 7 days and successfully transfer back
        vm.warp(block.timestamp + 7 days);
        vm.prank(ALICE);
        akolytes.transferFrom(ALICE, testAddy, 0);

        // Cooldown applies again
        vm.expectRevert(Akolytes.Cooldown.selector);
        akolytes.transferFrom(testAddy, ALICE, 0);

        // Advance another 7 days
        vm.warp(block.timestamp + 7 days);

        // Set testAddy to be mock sudo pool
        mockPairFactory.whitelistAddy(address(this));

        // Can transfer back and forth with no issues
        akolytes.transferFrom(testAddy, ALICE, 0);
        vm.prank(ALICE);
        akolytes.transferFrom(ALICE, testAddy, 0);
    }

    function test_royaltyDistroETH() public {
        // Mint ID 0 to msg.sender
        // Attempt to claim for ID 0
        mockMons.mint(0, 2);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;
        akolytes.tap_to_acquire_akolyte(ids);

        // Send 1 ETH to the akolytes contract
        payable(address(akolytes)).safeTransferETH(1 ether);

        // Accumulate the ETH
        akolytes.accumulateRoyalty(address(0));

        // Assert that the ETH accumulated is accounted for
        assertEq(akolytes.royaltyAccumulatedPerTokenType(address(0)), 1 ether);

        // Accumulate the royalty for ID 0 and ID 1
        uint256 royaltyClaimed = akolytes.claimRoyalties(address(0), ids);
        assertEq(royaltyClaimed, 2 * 1 ether / 512);

        // Send 1 ETH to the akolytes contract
        payable(address(akolytes)).safeTransferETH(1 ether);
        // Accumulate the royalty for ID 0, assert that the royalty gets accounted for during the claimRoyalties call
        royaltyClaimed = akolytes.claimRoyalties(address(0), ids);
        assertEq(royaltyClaimed, 2 * 1 ether / 512);

        // Accumulating royalties again should yield zero
        royaltyClaimed = akolytes.claimRoyalties(address(0), ids);
        assertEq(royaltyClaimed, 0);

        // Send 1 ETH to the akolytes contract
        payable(address(akolytes)).safeTransferETH(1 ether);
        uint256[] memory singleID = new uint256[](1);

        // Claim for just 1 ID
        royaltyClaimed = akolytes.claimRoyalties(address(0), singleID);
        assertEq(royaltyClaimed, 1 ether / 512);

        // Whitelist ALICE and transfer
        mockPairFactory.whitelistAddy(ALICE);
        akolytes.transferFrom(address(this), ALICE, 0);

        // Assert that cannot claim royalty if not owner
        vm.expectRevert(Akolytes.Akoless.selector);
        royaltyClaimed = akolytes.claimRoyalties(address(0), singleID);

        // Prank as Alice, assert that royalties of an already claimed ID = 0
        vm.prank(ALICE);
        royaltyClaimed = akolytes.claimRoyalties(address(0), singleID);
        assertEq(royaltyClaimed, 0);

        // Claim for ID 1, assert that royalties are as expected
        singleID[0] = 1;
        royaltyClaimed = akolytes.claimRoyalties(address(0), singleID);
        assertEq(royaltyClaimed, 1 ether / 512);
    }

    function test_royaltyHandlerOwnerIsAkolytes() public {
        assertEq(
            RoyaltyHandler(akolytes.ROYALTY_HANDER()).owner(), 
            address(akolytes));
    }

    function test_sudoSpecificInteractions() public {

        // Create new akolytes that is bound to the pair factory
        akolytes = new Akolytes(address(mockMons), address(pairFactory), address(0), address(0), address(0), address(0));

         // Mint ID 0 to msg.sender
        // Attempt to claim for ID 0
        mockMons.mint(0, 1);
        uint256[] memory ids = new uint256[](1);
        akolytes.tap_to_acquire_akolyte(ids);

        // Transfer to ALICE
        address testAddy = address(this);
        akolytes.transferFrom(testAddy, ALICE, 0);

        // Prank as ALICE
        vm.startPrank(ALICE);

        // Cannot transfer from ALICE to BOB
        vm.expectRevert(Akolytes.Cooldown.selector);
        akolytes.transferFrom(ALICE, BOB, 0);

        // Approve the collection and list it for sale
        uint256[] memory id = new uint256[](1);
        id[0] = 0;
        ERC721(address(akolytes)).setApprovalForAll(address(pairFactory), true);

        // Create new sudo pool
        // Check that ID 0 is now in the pair
        uint256 price = 0.1 ether;
        LSSVMPair pair = pairFactory.createPairERC721ETH(
            IERC721(address(akolytes)),
            ICurve(address(linearCurve)),
            ALICE,
            LSSVMPair.PoolType.TRADE,
            0,
            0,
            uint128(price),
            address(0),
            id
        );
        assertEq(akolytes.balanceOf(address(pair)), 1);
        assertEq(akolytes.ownerOf(0), address(pair));
        vm.stopPrank();

        // Check that we can buy ID 0
        (,,, uint256 amount,,) = pair.getBuyNFTQuote(0, 1);
        pair.swapTokenForSpecificNFTs{value: amount}(id, amount, address(this), false, address(0));

        // Check that we get 0.05/512 ether as royalties claimed
        uint256 royaltiesReceived = akolytes.claimRoyalties(address(0), id);
        uint256 expectedAmount = price / 512 / 20;
        assertEq(royaltiesReceived, expectedAmount);

        // Check that transferring to ALICE still fails
        vm.expectRevert(Akolytes.Cooldown.selector);
        akolytes.transferFrom(address(this), ALICE, 0);

        // Check that selling back to the pool succeeds
        ERC721(address(akolytes)).setApprovalForAll(address(pair), true);
        (,,, amount,,) = pair.getSellNFTQuote(0, 1);
        pair.swapNFTsForToken(id, amount, payable(address(this)), false, address(0));

        // Check that ALICE can withdraw the NFT
        vm.startPrank(ALICE);
        pair.withdrawERC721(IERC721(address(akolytes)), id);

        // Check that we get 0.05/512 ether as royalties claimed (as ALICE)
        royaltiesReceived = akolytes.claimRoyalties(address(0), id);
        expectedAmount = price / 512 / 20;
        assertEq(royaltiesReceived, expectedAmount);
        vm.stopPrank();
    }

    event Foo(string s);
    function test_tokenURI() public {

        Markov m = new Markov();

        // Create new akolytes that is bound to the pair factory
        akolytes = new Akolytes(address(mockMons), address(pairFactory), address(m), address(0), address(0), address(0));

        // Mint IDs 0 to 9 to msg.sender
        mockMons.mint(0, 10);
        uint256[] memory ids = new uint256[](10);

        // Attempt to claim for IDs 0 to 9
        for (uint i; i < 10; ++i) {
            ids[i] = i;
        }
        akolytes.tap_to_acquire_akolyte(ids);

        // Check the URI
        emit Foo(akolytes.tokenURI(1));
    }

    function test_gda() public {
        akolytes = new Akolytes(address(mockMons), address(pairFactory), address(0), address(gdaCurve), address(0), address(0));
        akolytes.setupGDA();
    }

    // Receive ETH
    receive() external payable {}
}