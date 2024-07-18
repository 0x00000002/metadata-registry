// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./SignersRegister.sol";
import "@ipfs-cid-solidity/Base32.sol";
import "@ipfs-cid-solidity/IPFS.sol";

string constant IPFS_URI = "ipfs://";

error UriExists(bytes32 token, bytes32 label);

contract URIsRegister is IPFS {
    /**
     * @notice Token can have multiple URIs, and we use labels to differentiate them.
     * @notice Labels are used by creators to "mark" their URIs.
     * @notice Label is an arbitrary bytes32 value.
     *
     * @dev MRTokenId = keccak256(contractAddress, tokenId)
     * @dev digest = keccak256(MRTokenId, attrId)
     * @dev uri = 'ipfs://' + cidv0(digest)
     *
     * @notice we use bytes32 over the string to save gas
     */

    mapping(bytes32 MRTokenId => mapping(bytes32 attrId => bytes32 keccak256hash))
        private _hash;

    // mapping(address contractAddress => bytes32[]) private _labels;

    /**
     * @notice Get all token uris associated with a particular token
     * @param MRTokenId The identifier for the token
     * @param attrId The identifier for the uri
     * @return uri string
     */
    function _getURI(
        bytes32 MRTokenId,
        bytes32 attrId
    ) internal view returns (string memory) {
        return
            string(abi.encodePacked(IPFS_URI, cidv1(_hash[MRTokenId][attrId])));
    }

    /**
     * @notice This function sets the URI for a given token.
     * @param MRTokenId The MR token identifier
     * @param attrId The attribute identifier for the token
     * @param digest The IPFS digest (sha2-256 hash) of the file
     */
    function _setUri(
        bytes32 MRTokenId,
        bytes32 attrId,
        bytes32 digest
    ) internal {
        if (_hash[MRTokenId][attrId] > 0) revert UriExists(MRTokenId, attrId);

        _hash[MRTokenId][attrId] = digest;
    }
}
