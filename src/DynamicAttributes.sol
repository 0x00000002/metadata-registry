// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Errors.sol";
import "./SignersRegister.sol";
import "./MultipleURIs.sol";

contract DynamicAttributes is Errors, AccessManaged, MultipleURIs {
    using ECDSA for bytes32;

    struct Attribute {
        address signer;
        bytes32 name; // keccak256(abi.encodePacked(attributeName));
    }

    mapping(bytes32 uri => Attribute) attributes;
    mapping(uint256 tokenId => mapping(bytes32 => uint256)) tokenAttributes;

    event AttributesAdded(
        bytes32 indexed studio,
        bytes32[] names,
        bytes32[] uris
    );
    event AttributesUpdated(
        uint256 indexed tokenId,
        bytes32[] indexed uris,
        uint256[] values
    );

    constructor(
        address manager_,
        address register_
    ) MultipleURIs(register_) AccessManaged(manager_) {}

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param attrs Attribute
     * @return uris Array of URIs
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttributes(
        Attribute[] calldata attrs
    ) public restricted returns (bytes32[] memory uris) {
        bytes32 studio = _register.getStudio(msg.sender);
        uris = _addAttributes(studio, attrs);
    }

    /**
     * @notice This function sets the value of an attribute for a given token.
     * @notice it doesn't check if token exists; attributes can be assigned in advance
     * @param data encoded data with list of tokens to mint and signature
     * @param signature The signature
     * @dev Can be called by anyone with a valid signed data
     */
    function setAttributes(bytes memory data, bytes memory signature) public {
        address signer = _register.validateSignature(data, signature);

        (uint256 tokenId, bytes32[] memory uris, uint256[] memory values) = abi
            .decode(data, (uint256, bytes32[], uint256[]));

        _setAttributes(tokenId, uris, values, signer);
    }

    /**
     * @notice This function sets the value of DA by the Attribute Owner
     */

    function setAttributes(
        uint256 tokenId,
        bytes32[] calldata uris,
        uint256[] calldata values
    ) public restricted {
        _setAttributes(tokenId, uris, values, _register.getSigner(msg.sender));
    }

    function _setAttributes(
        uint256 tokenId,
        bytes32[] memory uris,
        uint256[] memory values,
        address signer
    ) private {
        if (uris.length != values.length)
            revert InvalidArrays(
                ID_VALUES_MISMATCH,
                uris.length,
                values.length
            );

        for (uint256 i = 0; i < uris.length; i++) {
            bytes32 uri = uris[i];

            if (uri == bytes32(0)) revert EmptyURI(URI_DOES_NOT_EXIST, i);
            if (attributes[uri].signer != signer)
                revert InvalidAttribute(WRONG_ATTRIBUTE_OWNER, uri);

            tokenAttributes[tokenId][uri] = values[i];
        }

        emit AttributesUpdated(tokenId, uris, values);
    }

    /**
     * @notice This function can be used by inheriting contracts
     * @param studio Studio's name
     * @param attrs Array of attributes to create
     */
    function _addAttributes(
        bytes32 studio,
        Attribute[] memory attrs
    ) internal returns (bytes32[] memory uris) {
        uint256 total = attrs.length;
        uris = new bytes32[](total);
        bytes32[] memory names = new bytes32[](total);

        for (uint256 i = 0; i < attrs.length; i++) {
            bytes32 uri = keccak256(abi.encodePacked(studio, attrs[i].name));

            if (attrs[i].name.length == 0) revert InvalidInput(INVALID_NAME);
            if (attributes[uri].signer != address(0))
                revert InvalidAttribute(URI_IS_TAKEN, uri);

            attributes[uri] = attrs[i];
            uris[i] = uri;
            names[i] = attrs[i].name;
        }

        emit AttributesAdded(studio, names, uris);
    }
}
