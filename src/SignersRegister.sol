// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Errors.sol";

import "forge-std/console.sol";

contract SignersRegister is Errors, AccessManaged {
    using ECDSA for bytes32;

    // we want allow studios to have different accounts
    // for signing transactions and managing the signer account
    mapping(address account => address signer) private _managers;
    mapping(address signer => bool status) private _signers;

    event SignerUpdated(
        address indexed manager,
        address indexed signer,
        bool status
    );

    constructor(address manager) AccessManaged(manager) {}

    function getSigner(address addr) external view returns (address) {
        return _managers[addr];
    }

    function isSigner(address addr) external view returns (bool) {
        return _signers[addr];
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param data bytes encoded minting data
     * @param signature The signature passed from the caller
     * @return signer The signer address
     */
    function validateSignature(
        bytes calldata data,
        bytes calldata signature
    ) public view returns (address signer) {
        bytes32 messageHash = _hash(data);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        signer = _verify(ethSignedMessageHash, signature);
    }

    /**
     * @notice Add a manager and a signer
     * @dev This function can only be called by FV admins
     * @param manager The Studio's address to update
     * @param signer signer's address
     * @param status true/false = active/inactive
     */
    function addManager(
        address manager,
        address signer,
        bool status
    ) external restricted {
        if (manager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _managers[manager] = signer;
        _signers[signer] = status;
        emit SignerUpdated(manager, signer, status);
    }

    /**
     * @notice Set signer - true/false = active/inactive
     * @dev This function can only to called from contracts account managers with MANAGER
     * @param addr The Studio's address to update
     * @param signer signer's address
     */
    function setSigner(address addr, address signer, bool status) external {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        if (_managers[_msgSender()] == address(0) || _msgSender() != addr)
            revert InvalidInput(UNKNOWN_MANAGER);

        _managers[addr] = signer;
        _signers[signer] = status;

        emit SignerUpdated(addr, signer, status);
    }

    /**
     * @notice Encode arguments to generate a hash, which will be used for validating signatures
     * @dev This function can only be called inside the contract
     * @param data bytes encoded minting data
     * @return Encoded hash
     */
    function _hash(bytes memory data) private pure returns (bytes32) {
        return keccak256(abi.encode(data));
    }

    /**
     * @notice To verify the `token` is signed by the _signer
     * @dev This function can only be called inside the contract
     * @param ethSignedMessageHash The encoded hash used for signature
     * @param signature The signature passed from the caller
     * @return signer The address who signed the message
     */
    function _verify(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) private view returns (address signer) {
        signer = ethSignedMessageHash.recover(signature);
        if (!_signers[signer]) revert InvalidInput(UNKNOWN_SIGNER);
    }

    /**
     * @notice Prefixing a hash with "\x19Ethereum Signed Message\n", which required for recovering signer
     * @dev This function can only be called inside the contract
     * @param _messageHash hash that need to be prefixed
     * @return Prefixed hash
     */
    function _getEthSignedMessageHash(
        bytes32 _messageHash
    ) private pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}
