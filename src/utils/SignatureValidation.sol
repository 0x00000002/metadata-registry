// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Errors.sol";

import "forge-std/console.sol";

contract SignatureValidation is Errors, AccessManaged {
    using ECDSA for bytes32;

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param data bytes encoded minting data
     * @param signature The signature passed from the caller
     * @return signer The signer address
     */
    function getSigner(
        bytes calldata data,
        bytes calldata signature
    ) public view returns (address signer) {
        bytes32 messageHash = _hash(data);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        signer_ = _getSigner(ethSignedMessageHash, signature);
        if (signer != signer_) revert InvalidInput(UNKNOWN_SIGNER);
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
    function _getSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) private view returns (address signer) {
        signer == ethSignedMessageHash.recover(signature);
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
