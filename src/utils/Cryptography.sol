// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Cryptography {
    using ECDSA for bytes32;

    /**
     * @notice To verify that data was signed by the signer
     * @param signer The address who (presumably) signed the message
     * @param data message to sign
     * @param signature The signature passed from the caller (signed message)
     * @return bool if the signer is the address who signed the message
     */
    function verifySignature(
        address signer,
        bytes calldata data,
        bytes calldata signature
    ) public pure returns (bool) {
        address signer_ = extractSigner(data, signature);
        return signer == signer_;
    }

    /**
     * @notice Extracts signer from the signed message
     * @param data message to sign
     * @param signature The signature passed from the caller
     * @return signer The signer address
     */
    function extractSigner(
        bytes calldata data,
        bytes calldata signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(data)
            )
        );
        return ethSignedMessageHash.recover(signature);
    }
}
