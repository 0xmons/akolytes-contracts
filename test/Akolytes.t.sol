// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockPairFactory} from "./mocks/MockPairFactory.sol";
import {Akolytes} from "../src/Akolytes.sol";
import {RoyaltyHandler} from "../src/RoyaltyHandler.sol";

contract AkolytesTest is Test {

    Akolytes akolytes;
    MockERC721 mockMons;
    MockPairFactory mockPairFactory;

    address constant ALICE = address(123456789);

    function setUp() public {
        mockMons = new MockERC721();
        mockPairFactory = new MockPairFactory();
        akolytes = new Akolytes(address(mockMons), address(mockPairFactory));
    }

    function test_claimForMons() public {

        // Mint IDs 0 to 9 to msg.sender
        mockMons.mint(0, 10);
        uint256[] memory ids = new uint256[](10);

        // Attempt to claim for IDs 0 to 9
        for (uint i; i < 10; ++i) {
            ids[i] = i;
        }
        akolytes.claimForMons(ids);

        // Assert that msg.sender has 10
        assertEq(akolytes.balanceOf(address(this)), 10);

        // Attempt to claim for ALICE, expect it to fail
        vm.prank(ALICE);
        vm.expectRevert(Akolytes.Monless.selector);
        akolytes.claimForMons(ids);

        // Mint another one for ALICE to cliam
        vm.startPrank(ALICE);
        mockMons.mint(10, 1);
        uint256[] memory aliceId = new uint256[](1);
        aliceId[0] = 10;
        akolytes.claimForMons(aliceId);
        assertEq(akolytes.balanceOf(address(ALICE)), 1);
        vm.stopPrank();
    }

    function test_transferLock() public {

        // Mint ID 0 to msg.sender
        // Attempt to claim for ID 0
        mockMons.mint(0, 1);
        uint256[] memory ids = new uint256[](1);
        akolytes.claimForMons(ids);

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

    function test_royaltyHandlerOwnerIsAkolytes() public {
        assertEq(
            RoyaltyHandler(akolytes.ROYALTY_HANDER()).owner(), 
            address(akolytes));
    }
}