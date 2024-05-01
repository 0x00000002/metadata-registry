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
        bytes32 name; // bytes32(abi.encodePacked(attributeName))
    }

    mapping(bytes32 attrId => Attribute) private _attribute;
    mapping(uint256 tokenId => mapping(bytes32 => uint256)) private _value;
    bytes32[] private _tokenAttributes;

    event AttributesAdded(
        bytes32 indexed studio,
        bytes32[] attrNames,
        bytes32[] attrIds
    );
    event AttributesUpdated(
        uint256 indexed tokenId,
        bytes32[] indexed attrIds,
        uint256[] attrValues
    );

    constructor(
        address manager_,
        address register_
    ) MultipleURIs(register_) AccessManaged(manager_) {}

    function getAttribute(
        bytes32 attrId
    ) public view returns (Attribute memory) {
        return _attribute[attrId];
    }

    function getAttributesList() public view returns (bytes32[] memory) {
        return _tokenAttributes;
    }

    function getValue(
        uint256 tokenId,
        bytes32 attrId
    ) public view returns (uint256) {
        return _value[tokenId][attrId];
    }

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param attrs Attribute
     * @return attrIds Array of attribute IDs
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttributes(
        Attribute[] calldata attrs
    ) public restricted returns (bytes32[] memory attrIds) {
        bytes32 studio = _register.getName(msg.sender);
        attrIds = _addAttributes(studio, attrs);
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

        (
            uint256 tokenId,
            bytes32[] memory attrIds,
            uint256[] memory values
        ) = abi.decode(data, (uint256, bytes32[], uint256[]));

        _setAttributes(tokenId, attrIds, values, signer);
    }

    /**
     * @notice This function sets the value of DA by the Attribute Owner
     */

    function setAttributes(
        uint256 tokenId,
        bytes32[] calldata attrIds,
        uint256[] calldata values
    ) public restricted {
        _setAttributes(
            tokenId,
            attrIds,
            values,
            _register.getSigner(msg.sender)
        );
    }

    /**
     * @notice This function can be used by inheriting contracts
     * @param studio Studio's name
     * @param attrs Array of attributes to create
     */
    function _addAttributes(
        bytes32 studio,
        Attribute[] memory attrs
    ) internal returns (bytes32[] memory attrIds) {
        uint256 total = attrs.length;
        attrIds = new bytes32[](total);
        bytes32[] memory names = new bytes32[](total);

        for (uint256 i = 0; i < attrs.length; i++) {
            bytes32 id = keccak256(abi.encodePacked(studio, attrs[i].name));

            if (attrs[i].name.length == 0) revert InvalidInput(INVALID_NAME);
            if (_attribute[id].signer != address(0))
                revert InvalidAttribute(ATTRIBUTE_EXISTS, id);

            _attribute[id] = attrs[i];
            attrIds[i] = id;
            names[i] = attrs[i].name;
            _tokenAttributes.push(id);
        }
        emit AttributesAdded(studio, names, attrIds);
    }

    function _setAttributes(
        uint256 tokenId,
        bytes32[] memory attrIds,
        uint256[] memory values,
        address signer
    ) private {
        if (attrIds.length != values.length)
            revert InvalidArrays(
                ID_VALUES_MISMATCH,
                attrIds.length,
                values.length
            );

        for (uint256 i = 0; i < attrIds.length; i++) {
            bytes32 id = attrIds[i];

            if (id == bytes32(0))
                revert NonExistingAttribute(ATTRIBUTE_NOT_EXIST, id, i);
            if (_attribute[id].signer != signer)
                revert InvalidAttribute(WRONG_ATTRIBUTE_OWNER, id);

            _value[tokenId][id] = values[i];
        }

        emit AttributesUpdated(tokenId, attrIds, values);
    }
}
