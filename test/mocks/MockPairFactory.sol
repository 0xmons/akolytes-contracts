// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ICurve} from "lssvm2/bonding-curves/ICurve.sol";
import {LSSVMPair} from "lssvm2/LSSVMPair.sol";

import {ILSSVMPairFactoryLike} from "../../src/ILSSVMPairFactory.sol";

contract MockPairFactory is ILSSVMPairFactoryLike {

    mapping(address => bool) isAllowed;

    function whitelistAddy(address a) external {
        isAllowed[a] = true;
    }

    function isValidPair(address pairAddress) external view returns (bool) {
        if (isAllowed[pairAddress]) {
            return true;
        }
        else {
            return false;
        }
    }

    function createPairERC721ETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        address _propertyChecker,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPair pair) {}

    function createPairERC721ERC20(ILSSVMPairFactoryLike.CreateERC721ERC20PairParams calldata params) external returns (LSSVMPair pair) {}

}