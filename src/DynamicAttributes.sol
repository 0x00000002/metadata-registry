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
     * @param uris URI of the attribute
     * @param attrs Attribute
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttributes(
        bytes32[] calldata uris,
        Attribute[] calldata attrs
    ) public restricted {
        if (uris.length != attrs.length)
            revert InvalidArrays(ID_VALUES_MISMATCH, uris.length, attrs.length);

        for (uint256 i = 0; i < uris.length; i++) {
            if (uris[i] == bytes32(0)) revert InvalidInput(INVALID_URI);
            if (attrs[i].name.length == 0) revert InvalidInput(INVALID_NAME);

            attributes[uris[i]] = attrs[i];
        }
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
    ) internal {
        if (uris.length != values.length)
            revert InvalidArrays(
                ID_VALUES_MISMATCH,
                uris.length,
                values.length
            );

        for (uint256 i = 0; i < uris.length; i++) {
            bytes32 uri = uris[i];
            uint256 value = values[i];

            if (uri == bytes32(0)) revert EmptyURI(INVALID_URI, i);
            if (attributes[uri].signer != signer)
                revert InvalidAttribute(WRONG_ATTRIBUTE_OWNER, uri);

            tokenAttributes[tokenId][uri] = value;
        }

        emit AttributesUpdated(tokenId, uris, values);
    }
}
