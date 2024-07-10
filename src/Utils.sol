// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Errors.sol";

import "forge-std/console.sol";

contract Utils is Errors {
    using ECDSA for bytes32;

    // Studio can have many managers, but only one BackEnd signer
    mapping(address account => bytes32 studioName) private _name;
    mapping(address account => address signer) private _signer;
    mapping(address signer => bool status) private _status;

    event SignerUpdated(
        bytes32 indexed name, // bytes32(abi.encodePacked(studioName))
        address indexed acc,
        address indexed signer,
        bool status
    );

    constructor(address manager) AccessManaged(manager) {}

    function getSigner(address acc) external view returns (address) {
        return _signer[acc];
    }

    function getName(address acc) external view returns (bytes32) {
        return _name[acc];
    }

    function isSigner(address acc) external view returns (bool) {
        return _status[acc];
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
     * @notice Update the signer's status
     * @param acc Studio address to manage signer's status
     * @param signer Signer address
     * @param status true/false = active/inactive
     * @dev This function can only be called by FV admins
     */
    function update(
        bytes32 name,
        address acc,
        address signer,
        bool status
    ) external restricted {
        if (acc == address(0)) revert InvalidInput(INVALID_ADDRESS);
        if (_name[acc] != bytes32(0)) revert InvalidInput(STUDIO_EXISTS);
        _name[acc] = name;
        _signer[acc] = signer;
        _status[signer] = status;
        emit SignerUpdated(name, acc, signer, status);
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
        if (!_status[signer]) revert InvalidInput(UNKNOWN_SIGNER);
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
