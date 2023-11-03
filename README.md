# akolytes

akolytes is an ERC721 contract that manages its own royalties, liquidity, and issuance. The textual metadata is generated on-chain and makes use of a novel Markov chain structure.

## Overview

`Akolytes.sol` is the main contract. It handles the following:

- Creates an initial GDA pool for issuance
- Creates a trade pool for immediate liquidity
- Redirects royalties back to itself, claimable pro-rata by holders
- On-chain metadata (name generation, traits, and description)

`Markov.sol` implements a Markov chain for novel text generation. To save on gas and compute, it makes a few simplifications:

- 256 word vocabulary
- Transition matrix is limited to discrete probabilities in increments of 1/32 (i.e. one word can at most map onto 32 other words with equal probaility)

## Licensing

The contracts are all under the permissive MIT license. Please feel free to fork and utilize. The metadata and akolyte images are licensed under CC0. See assets [here](https://github.com/0xmons/akolytes-images/tree/main).