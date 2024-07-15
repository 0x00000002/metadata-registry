// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./SignersRegister.sol";

/**
 * @notice The contract emulates the ERC-7160 interface
 * @notice although the functions have different signatures
 * @notice to accommodate both `collectionId` and `tokenId`
 */

contract MetadataRegister {
    struct Metadata {
        uint32 nonce;
        uint32 pinIndex;
        bool pinned;
        bytes32[] uris;
    }

    mapping(bytes32 token => Metadata) private _tokenURIs;

    /**
     * @notice Get all token uris associated with a particular token
     * @param contractAddress The address of the contract
     * @param tokenId The identifier for the token
     * @return index An unisgned integer that specifies which uri is pinned for a token (or 0 if no pinned uri)
     * @return uris A string array of all uris associated with a token
     * @return pinned A boolean showing if the token has pinned metadata or not
     */
    function tokenURIs(
        address contractAddress,
        uint256 tokenId
    )
        external
        view
        returns (uint256 index, bytes32[] memory uris, bool pinned)
    {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        Metadata memory m = _tokenURIs[token];

        return (m.pinIndex, m.uris, m.pinned);
    }

    function constructURI(bytes32 token) external returns (bytes32 uri) {
        Metadata storage m = _tokenURIs[token];

        // See: https://github.com/multiformats/multihash
        // IFPS uri = hash_function + size + tokenDigest
        // tokenDigest = abi.encodePacked(token,nonce)
        // token = keccak256(abi.encodePacked(contractAddress,tokenId))
        bytes32 tokenUri = keccak256(
            abi.encodePacked("0x12", "0x20", token, m.nonce)
        );
        uri = bytes32(abi.encodePacked("ipfs://", s));
    }

    /**
     * @notice Pin a specific token uri for a particular token
     * @param contractAddress The address of the contract
     * @param tokenId The identifier of the token
     * @return pinned True if the token has a pinned uri
     */
    function hasPinnedTokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool pinned) {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        return _tokenURIs[token].pinned;
    }

    /**
     * @notice Pin a specific token uri for a particular token
     * @param token The identifier of the token
     * @param index The index in the URIs array that should be pinned
     */
    function _pinTokenURI(bytes32 token, uint32 index) internal {
        Metadata storage m = _tokenURIs[token];
        m.pinIndex = index;
        m.pinned = true;
    }

    /**
     * @notice Unpin metadata for a particular token
     * @param token The identifier of the token
     */
    function _unpinTokenURI(bytes32 token) internal {
        Metadata storage m = _tokenURIs[token];
        m.pinIndex = 0;
        m.pinned = false;
    }
}
