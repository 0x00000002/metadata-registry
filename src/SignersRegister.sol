// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./utils/Cryptography.sol";

string constant UNKNOWN_SIGNER = "Unknown signer";
string constant INVALID_ADDRESS = "Invalid address";
string constant STUDIO_EXISTS = "Studio exist";

error InvalidSigner(string errMsg);

contract SignersRegister is Cryptography, AccessManaged {
    mapping(address acc => address) private _signer;
    mapping(address signer => bool) private _status;

    event SignerSet(address indexed acc, address indexed signer, bool status);

    constructor(address manager) AccessManaged(manager) {}

    function getSigner(address acc) external view returns (address) {
        return _signer[acc];
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
        signer = extractSigner(data, signature);
        if (!_status[signer]) revert InvalidSigner(UNKNOWN_SIGNER);
    }

    /**
     * @notice Update the signer's status
     * @param acc Studio address to manage signer's status
     * @param signer Signer address
     * @param status true/false = active/inactive
     * @dev This function can only be called by FV admins
     */
    function setSigner(
        address acc,
        address signer,
        bool status
    ) external restricted {
        if (acc == address(0)) revert InvalidSigner(INVALID_ADDRESS);
        _signer[acc] = signer;
        _status[signer] = status;

        emit SignerSet(acc, signer, status);
    }
}
