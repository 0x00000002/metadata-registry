// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "forge-std/console.sol";

contract Cryptography {
    using ECDSA for bytes32;

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param data signed message
     * @param signature The signature passed from the caller
     * @return bool if the signer is the address who signed the message
     */
    function verifySignature(
        address signer,
        bytes calldata data,
        bytes calldata signature
    ) public pure returns (bool) {
        bytes32 messageHash = _hash(data);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        address _signer = ethSignedMessageHash.recover(signature);

        return signer == _signer;
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param data signed message
     * @param signature The signature passed from the caller
     * @return signer The signer address
     */
    function extractSigner(
        bytes calldata data,
        bytes calldata signature
    ) public pure returns (address) {
        bytes32 messageHash = _hash(data);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        return ethSignedMessageHash.recover(signature);
    }

    /**
     * @notice To validate the `signature` is signed by the _signer
     * @param msgHash The encoded hash used for signature
     * @param signature The signature passed from the caller
     * @return signer The address who signed the message
     */
    function extractSigner(
        bytes32 msgHash,
        bytes calldata signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(msgHash);
        return ethSignedMessageHash.recover(signature);
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
