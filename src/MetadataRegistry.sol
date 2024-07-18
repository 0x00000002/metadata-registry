// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SignersRegister.sol";
import "./AttributesRegister.sol";
import "./URIsRegister.sol";

import "forge-std/console.sol"; // TODO: remove it

contract MetadataRegistry is URIsRegister, AttributesRegister, AccessManaged {
    SignersRegister private _sr;

    constructor(address manager_, address register_) AccessManaged(manager_) {
        _sr = SignersRegister(register_);
    }

    event AttributesUpdated(
        address indexed tokenContract,
        uint32 indexed tokenId,
        bytes32[] indexed attrIds,
        uint256[] attrValues
    );

    event AttributesAdded(address indexed tokenContract, bytes32[] attrIds);
    event TokenUriPinned(
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 index
    );
    event TokenUriUnpinned(
        address indexed contractAddress,
        uint256 indexed tokenId
    );

    // ! ----------------- Attributes functions -----------------

    /**
     * @notice This function returns the list of attributes for a given token.
     * @param tokenContract The address of the token contract
     * @return attrIds Array of attribute IDs
     */
    function getAttributesList(
        address tokenContract
    ) external view returns (bytes32[] memory attrIds) {
        return _getAttriibutesList(tokenContract);
    }

    function getAttributeValue(
        address contractAddress,
        uint256 tokenId,
        bytes32 attrId
    ) external view returns (uint256) {
        return
            _getAttributeValue(_getMRTokenId(contractAddress, tokenId), attrId);
    }

    /**
     * @notice This function returns Attribute.Attribute for a given token.
     * @param attrId Attribute ID
     * @return attr Attribute
     */
    function getAttribute(
        bytes32 attrId
    ) external view returns (Attribute memory) {
        return _getAttribute(attrId);
    }

    /**
     * @notice This function returns the values of the attributes for a given token.
     * @param attrIds Array of attribute IDs
     * @return attrs Array of Attributes
     */
    function getAttributes(
        bytes32[] memory attrIds
    ) external view returns (Attribute[] memory attrs) {
        attrs = new Attribute[](attrIds.length);
        for (uint256 i = 0; i < attrIds.length; i++) {
            attrs[i] = _getAttribute(attrIds[i]);
        }
    }

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param attrs Attributes
     * @return attrIds Array of attribute IDs
     * @dev Can be called only by pre-approved accounts (studios/creators)
     */
    function addAttributes(
        address tokenContract,
        Attribute[] calldata attrs
    ) external restricted returns (bytes32[] memory attrIds) {
        attrIds = _addAttributes(tokenContract, attrs);
        emit AttributesAdded(tokenContract, attrIds);
    }

    /**
     * @notice This function sets the value of an attribute for a given token.
     * @notice It doesn't check if token exists to make it possible
     * @notice to add attributes to tokens in advance, before minting
     * @param data encoded data with list of tokens to mint and signature
     * @param signature The signature
     * @dev Can be called by anyone with a valid signed data
     */
    function setAttributes(bytes memory data, bytes memory signature) external {
        address signer = _sr.validateSignature(data, signature);
        (
            address contractAddress,
            uint256 tokenId,
            bytes32[] memory attrIds,
            uint256[] memory values
        ) = abi.decode(data, (address, uint256, bytes32[], uint256[]));

        _setAttributes(
            _getMRTokenId(contractAddress, tokenId),
            attrIds,
            values,
            signer
        );
    }

    /**
     * @notice This function sets the values of attributes
     * @param attrIds Array of attribute IDs
     * @param values Array of attribute values
     * @dev Can be called only by pre-approved accounts (studios/creators)
     */
    function setAttributes(
        address contractAddress,
        uint256 tokenId,
        bytes32[] calldata attrIds,
        uint256[] calldata values
    ) external restricted {
        _setAttributes(
            _getMRTokenId(contractAddress, tokenId),
            attrIds,
            values,
            _sr.getSigner(msg.sender)
        );
    }

    /**
     * @notice This function changes the signer of the attribute
     * @param attrIds Array of attribute IDs
     * @param newSigners Array of new signers
     * @dev Can be called only by the MR contract administrator
     */
    function changeAttributeSigner(
        bytes32[] calldata attrIds,
        address[] memory newSigners
    ) external restricted {
        uint256 total = attrIds.length;
        if (attrIds.length != newSigners.length)
            revert InvalidAttributesArrays(
                ARRAYS_LENGTHS_MISMATCH,
                total,
                newSigners.length
            );

        for (uint256 i = 0; i < total; i++) {
            _setAttributeOwner(attrIds[i], newSigners[i]);
        }
    }

    // ! ----------------- URI functions -----------------

    /**
     * @notice Get all token uris associated with a particular token
     * @param contractAddress The address of the contract
     * @param tokenId The identifier for the token
     * @param label The identifier for the uri
     * @return uri string
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId,
        bytes32 label
    ) external view returns (string memory) {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        return _getURI(token, label);
    }

    /**
     * @notice This function sets the URI for a given token.
     * @param contractAddress The address of the contract
     * @param tokenId The identifier for the token
     * @param label The identifier for the uri
     * @dev Can be called only by pre-approved accounts (studios/creators)
     */
    function addURI(
        address contractAddress,
        uint256 tokenId,
        bytes32 label,
        bytes32 digest
    ) external restricted {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        _setUri(token, label, digest);
    }

    // ! ----------------- Private functions -----------------

    /**
     * @notice This function updates the value of an attribute for a given token.
     * @param attrIds Array of attribute IDs
     * @param values Array of attribute values
     */
    function _setAttributes(
        bytes32 tokenId,
        bytes32[] memory attrIds,
        uint256[] memory values,
        address signer
    ) private {
        uint256 total = attrIds.length;
        if (values.length != total)
            revert InvalidAttributesArrays(
                ID_VALUES_MISMATCH,
                attrIds.length,
                values.length
            );
        for (uint256 i = 0; i < total; i++) {
            _setAttribute(tokenId, attrIds[i], values[i], signer);
        }
    }

    /**
     * @notice This function generates a unique MetadataRegistry's token ID
     * @param contractAddress The address of the contract
     * @param tokenId The contract's identifier for the token (uint256)
     * @return tokenId The unique, MetadataRegistry's token ID (bytes32)
     */
    function _getMRTokenId(
        address contractAddress,
        uint256 tokenId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress, tokenId));
    }
}
