// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./SignersRegister.sol";
import "@ipfs-cid-solidity/Base32.sol";
import "@ipfs-cid-solidity/IPFS.sol";

string constant IPFS_URI = "ipfs://";

error UriExists(bytes32 token, bytes32 label);
error LabelExists(address contractAddress, bytes32 label);

contract URIsRegister is IPFS {
    /**
     * @notice Token can have multiple URIs, and we use labels to differentiate them.
     * @notice Labels are used by creators to "mark" their URIs.
     * @notice Label is an arbitrary bytes32 value.
     *
     * @dev token = keccak256(contractAddress,tokenId)
     * @dev digest = keccak256(token,label)
     * @dev uri = 'ipfs://' + cidv0(digest)
     *
     * @notice we use bytes32 over the string to save gas
     */

    mapping(bytes32 token => mapping(bytes32 label => bytes32)) private _digest;
    mapping(address contractAddress => bytes32[]) private _labels;

    /**
     * @notice Get all token uris associated with a particular token
     * @param token The identifier for the token
     * @param label The identifier for the uri
     * @return uri string
     */
    function _getURI(
        bytes32 token,
        bytes32 label
    ) internal view returns (string memory) {
        return string(abi.encodePacked(IPFS_URI, cidv1(_digest[token][label])));
    }

    /**
     * @notice Get all labels associated with a particular contract
     * @param contractAddress The address of the contract
     * @return labels Array of labels
     */
    function _getLabels(
        address contractAddress
    ) internal view returns (bytes32[] memory) {
        return _labels[contractAddress];
    }

    /**
     * @notice Add a new label to the contract
     * @param contractAddress The address of the contract
     * @param label The identifier for the uri
     */
    function _addLabel(address contractAddress, bytes32 label) internal {
        for (uint256 i = 0; i < _labels[contractAddress].length; i++) {
            if (_labels[contractAddress][i] == label) {
                revert LabelExists(contractAddress, label);
            }
        }
        _labels[contractAddress].push(label);
    }

    /**
     * @notice This function sets the URI for a given token.
     * @param token The identifier for the token
     * @param label The identifier for the uri
     * @param digest The IPFS digest (sha2-256 hash) of the file
     * @dev Can be called only by pre-approved accounts (studios/creators)
     */
    function _setUri(bytes32 token, bytes32 label, bytes32 digest) internal {
        if (_digest[token][label] > 0) revert UriExists(token, label);

        _digest[token][label] = digest;
    }
}
