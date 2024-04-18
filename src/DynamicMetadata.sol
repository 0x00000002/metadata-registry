// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Errors.sol";
import "./SignersRegister.sol";
import "./interfaces/IERC7160.sol";
import "./interfaces/IERC4906.sol";

contract DynamicMetadata is Errors, IERC7160, AccessManaged {
    using ECDSA for bytes32;

    SignersRegister private _register;

    constructor(address manager_) AccessManaged(manager_) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC4906).interfaceId ||
            interfaceId == type(IERC7160).interfaceId;
    }

    /// @notice Get all token uris associated with a particular token
    /// @dev If a token uri is pinned, the index returned SHOULD be the index in the string array
    /// @dev This call MUST revert if the token does not exist
    /// @param tokenId The identifier for the nft
    /// @return index An unisgned integer that specifies which uri is pinned for a token (or the default uri if unpinned)
    /// @return uris A string array of all uris associated with a token
    /// @return pinned A boolean showing if the token has pinned metadata or not
    function tokenURIs(
        uint256 tokenId
    )
        external
        view
        returns (uint256 index, string[] memory uris, bool pinned)
    {}

    /// @notice Pin a specific token uri for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriPinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @param tokenId The identifier of the nft
    /// @param index The index in the string array returned from the `tokenURIs` function that should be pinned for the token
    function pinTokenURI(uint256 tokenId, uint256 index) external {}

    /// @notice Unpin metadata for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriUnpinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @dev It is up to the developer to define what this function does and is intentionally left open-ended
    /// @param tokenId The identifier of the nft
    function unpinTokenURI(uint256 tokenId) external {}

    /// @notice Check on-chain if a token id has a pinned uri or not
    /// @dev This call MUST revert if the token does not exist
    /// @dev Useful for on-chain mechanics that don't require the tokenURIs themselves
    /// @param tokenId The identifier of the nft
    /// @return pinned A bool specifying if a token has metadata pinned or not
    function hasPinnedTokenURI(
        uint256 tokenId
    ) external view returns (bool pinned) {}

    function updateRegister(address addr) external restricted {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _register = new SignersRegister(addr);
    }
}
