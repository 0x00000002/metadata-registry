// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Errors.sol";

contract Register is Errors, AccessManaged {
    using ECDSA for bytes32;

    mapping(address => bool) private _signers;

    event SignerUpdated(address indexed manager, address newSigner);

    constructor(address manager) AccessManaged(manager) {}

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
     * @notice Update signer - true/false = active/inactive
     * @dev This function can only to called from contracts or wallets with MANAGER
     * @param addr The signer address to update
     * @param status The status of the signer (active/inactive)
     */
    function setSigner(address addr, bool status) external restricted {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _signers[addr] = status;
        emit SignerUpdated(msg.sender, addr);
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
        if (_signers[signer] != true) revert InvalidInput(UNKNOWN_SIGNER);
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
