// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @dev Futureverse Swappable - Roles for testing Access Managed contract
 */

uint64 constant ADMIN_ROLE = type(uint64).min; // the same as in AccessManager.sol
uint64 constant PUBLIC_ROLE = type(uint64).max; // the same as in AccessManager.sol

uint64 constant FV_CSO = 10;

// AccessManager.sol roles
uint64 constant FV_AM_ADMIN = 1_000; // to add/remove signers to Multisig
uint64 constant FV_AM_MULTISIG = 1_001; // Multisig contract's role

// Multisig.sol roles
uint64 constant FV_MULTISIG_ADMIN = 2_001;
uint64 constant FV_MULTISIG_SIGNER_NO_DELAY = 2_002;
uint64 constant FV_MULTISIG_SIGNER_1HR_DELAY = 2_003;

// SignersRegister.sol roles
uint64 constant FV_SR_MANAGER = 3_001;

// DynamicAttributes.sol roles
uint64 constant FV_DA_MANAGER = 5_001;

// NFT.sol roles
uint64 constant NFT_MANAGER = 100_001;
