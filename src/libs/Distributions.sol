// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Distributions
library Distributions {
    // Start and end are inclusive for all of these
    // Uniform distribution
    function d1(
        uint256 seed
    ) public pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 diff = end + 1 - start;
        result = (seed % diff) + start;
    }

    // Modal distribution, centered on (start+end)/2
    function d2(
        uint256 seed
    ) public pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 subresult1 = d1(seed);
        uint256 seed2 = uint256(keccak256(abi.encode(seed, start, end)));
        uint256 subresult2 = d1(seed2);
        result = (subresult1 + subresult2) / 2;
    }

    // Symmetric distribution, with max density on start and end and least density on (start+end)/2
    function d3(
        uint256 seed
    ) public pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        uint256 midpoint = (start + end) / 2;
        uint256 d2Value = d2(seed);
        if (d2Value >= midpoint) {
            result = end - (d2Value - midpoint);
        } else {
            result = start + (midpoint - d2Value);
        }
    }

    // Even-favored distribution
    // i.e., if odd, re-rolls
    function d4(
        uint256 seed
    ) public pure returns (uint256 result) {
        uint256 start = 0;
        uint256 end = 512;
        result = d1(seed);
        if (result % 2 == 1) {
            result = d1(
                uint256(keccak256(abi.encode(seed, start, end)))
            );
        }
    }

    // ???
    function d5(
        uint256 seed
    ) public pure returns (uint256 result) {
        uint256 selector = seed % 4;
        uint256 newSeed = uint256(
            keccak256(abi.encode(seed / d1(seed)))
        );
        if (selector == 0) {
            result = d3(newSeed);
        } else if (selector == 1) {
            result = d1(newSeed);
        } else if (selector == 2) {
            result = d2(newSeed);
        } else if (selector == 3) {}
        result = d4(newSeed);
    }

    function d6(uint256 id) public pure returns (uint256) {
      if (id == 0) {
        return 0;
      }
      for (uint i = 1; i < id/2; i++) {
        uint result = id/i;
        if (result == 0) {
          return 1;
        }
      }
      return 2;
    }
}