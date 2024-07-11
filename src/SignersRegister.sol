// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./utils/Cryptography.sol";

string constant UNKNOWN_SIGNER = "Unknown signer";
string constant INVALID_ADDRESS = "Invalid address";
string constant STUDIO_EXISTS = "Studio exist";

error InvalidSigner(string errMsg);

contract SignersRegister is Cryptography, AccessManaged {
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
    function update(
        bytes32 name,
        address acc,
        address signer,
        bool status
    )
        external
        restricted // we can pass signed message here instead of `restricted`
    {
        if (acc == address(0)) revert InvalidSigner(INVALID_ADDRESS);
        if (_name[acc] != bytes32(0)) revert InvalidSigner(STUDIO_EXISTS);
        _name[acc] = name;
        _signer[acc] = signer;
        _status[signer] = status;
        emit SignerUpdated(name, acc, signer, status);
    }
}
