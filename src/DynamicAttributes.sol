// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Errors.sol";
import "./Register.sol";
import "./interfaces/IERC7160.sol";
import "./interfaces/IERC4906.sol";

contract DynamicAttributes is Errors, IERC7160, AccessManaged {
    using ECDSA for bytes32;

    Register private _register;

    struct Attribute {
        address owner;
        string name;
    }

    mapping(bytes32 uri => Attribute) attributes;
    mapping(uint256 tokenId => mapping(bytes32 => uint256)) tokenAttributes;

    event AttributeSet(
        uint256 indexed tokenId,
        bytes32 indexed uri,
        uint256 value
    );

    constructor(address manager_) AccessManaged(manager_) {}

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param uri URI of the attribute
     * @param attr Attribute
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttribute(
        bytes32 uri,
        Attribute calldata attr
    ) public restricted {
        if (attributes[uri].owner != _msgSender())
            revert InvalidAttribute(WRONG_OWNER, uri);

        if (uri == bytes32(0)) revert InvalidInput(INVALID_URI);
        if (bytes(attr.name).length == 0) revert InvalidInput(INVALID_NAME);

        attributes[uri] = attr;
    }

    /**
     * @notice This function sets the value of an attribute for a given token.
     * @notice it doesn't check if token exists; attributes can be assigned in advance
     * @param data encoded data with list of tokens to mint and signature
     * @param signature The signature
     * @dev Can be called by anyone with a valid signed data
     */
    function setAttribute(
        bytes calldata data,
        bytes calldata signature
    ) public restricted {
        address signer = _register.validateSignature(data, signature);

        (uint256 tokenId, bytes32[] memory ids, uint256[] memory values) = abi
            .decode(data, (uint256, bytes32[], uint256[]));

        if (ids.length != values.length)
            revert InvalidArrays(ID_VALUES_MISMATCH, ids.length, values.length);

        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 uri = ids[i];
            uint256 value = values[i];

            if (uri == bytes32(0)) revert EmptyURI(INVALID_URI, i);
            if (attributes[uri].owner != signer)
                revert InvalidAttribute(WRONG_OWNER, uri);

            tokenAttributes[tokenId][uri] = value;
            emit AttributeSet(tokenId, uri, value);
        }
    }

    function updateRegister(address addr) external restricted {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _register = new Register(addr);
    }

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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC7160).interfaceId;
    }
}
