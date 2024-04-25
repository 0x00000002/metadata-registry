// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Errors.sol";
import "./SignersRegister.sol";
import "./MultipleURIs.sol";

contract DynamicAttributes is Errors, AccessManaged {
    using ECDSA for bytes32;

    SignersRegister private _register;

    struct Attribute {
        address signer;
        bytes32 name; // keccak256(abi.encodePacked(attributeName));
    }

    mapping(bytes32 uri => Attribute) attributes;
    mapping(uint256 tokenId => mapping(bytes32 => uint256)) tokenAttributes;

    event AttributeSet(
        uint256 indexed tokenId,
        bytes32 indexed uri,
        uint256 value
    );

    constructor(address manager_, address register_) AccessManaged(manager_) {
        _register = SignersRegister(register_);
    }

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param uri URI of the attribute
     * @param attr Attribute
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttribute(bytes32 uri, Attribute calldata attr) public {
        if (uri == bytes32(0)) revert InvalidInput(INVALID_URI);
        if (attr.name.length == 0) revert InvalidInput(INVALID_NAME);

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
    ) public {
        address signer = _register.validateSignature(data, signature);

        (uint256 tokenId, bytes32[] memory ids, uint256[] memory values) = abi
            .decode(data, (uint256, bytes32[], uint256[]));

        if (ids.length != values.length)
            revert InvalidArrays(ID_VALUES_MISMATCH, ids.length, values.length);

        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 uri = ids[i];
            uint256 value = values[i];

            if (uri == bytes32(0)) revert EmptyURI(INVALID_URI, i);
            if (attributes[uri].signer != signer)
                revert InvalidAttribute(WRONG_ATTRIBUTE_OWNER, uri);

            tokenAttributes[tokenId][uri] = value;
            emit AttributeSet(tokenId, uri, value);
        }
    }
}
