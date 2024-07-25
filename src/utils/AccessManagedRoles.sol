// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

/**
 * @dev Roles for testing Access Managed contract
 */

uint64 constant ADMIN_ROLE = type(uint64).min; // the same as in AccessManager.sol
uint64 constant PUBLIC_ROLE = type(uint64).max; // the same as in AccessManager.sol

// SignersRegister.sol roles
uint64 constant SR_MANAGER = 3_001;

// NFT.sol roles
uint64 constant STUDIO_MANAGER = 100_001;
