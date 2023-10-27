// // SPDX-License-Identifier: AGPL-3.0
// pragma solidity ^0.8.20;

// import "forge-std/Script.sol";

// import {Akolytes} from "../src/Akolytes.sol";

// contract AkolytesDeploy is Script {

//   function run() external returns (Akolytes a) {
//       uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
//       vm.startBroadcast(deployerPrivateKey);
//       a = new Akolytes(address(0), address(0));
//       vm.stopBroadcast();
//   }
// }