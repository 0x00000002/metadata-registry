// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SignersRegister.sol";
import "./AttributesRegister.sol";
import "./MetadataRegister.sol";

contract MetadataRegistry is
    AttributesRegister,
    MetadataRegister,
    AccessManaged
{
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

    /**
     * @notice This function returns the list of attributes for a given token.
     * @param tokenContract The address of the token contract
     * @return attrIds Array of attribute IDs
     */
    function getAttributesList(
        address tokenContract
    ) public view returns (bytes32[] memory attrIds) {
        return _getAttriibuteList(tokenContract);
    }

    /**
     * @notice This function returns Attribute.Attribute for a given token.
     * @param attrId Attribute ID
     * @return attr Attribute
     */
    function getAttribute(
        bytes32 attrId
    ) public view returns (Attribute memory) {
        return _getAttribute(attrId);
    }

    /**
     * @notice This function returns the values of the attributes for a given token.
     * @param attrIds Array of attribute IDs
     * @return attrs Array of Attributes
     */
    function getAttributes(
        bytes32[] memory attrIds
    ) public view returns (Attribute[] memory attrs) {
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
    ) public restricted returns (bytes32[] memory attrIds) {
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
    function setAttributes(bytes memory data, bytes memory signature) public {
        address signer = _sr.validateSignature(data, signature);
        (bytes32[] memory attrIds, uint256[] memory values) = abi.decode(
            data,
            (bytes32[], uint256[])
        );

        _setAttributes(attrIds, values, signer);
    }

    /**
     * @notice This function sets the values of attributes
     * @param attrIds Array of attribute IDs
     * @param values Array of attribute values
     * @dev Can be called only by pre-approved accounts (studios/creators)
     */
    function setAttributes(
        bytes32[] calldata attrIds,
        uint256[] calldata values
    ) public restricted {
        address signer = _sr.getSigner(msg.sender);
        _setAttributes(attrIds, values, signer);
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
    ) public restricted {
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

    /**
     * @notice This function updates the value of an attribute for a given token.
     * @param attrIds Array of attribute IDs
     * @param values Array of attribute values
     */
    function _setAttributes(
        bytes32[] memory attrIds,
        uint256[] memory values,
        address signer
    ) internal {
        uint256 total = attrIds.length;
        if (values.length != total)
            revert InvalidAttributesArrays(
                ID_VALUES_MISMATCH,
                attrIds.length,
                values.length
            );
        for (uint256 i = 0; i < total; i++) {
            _setAttribute(attrIds[i], values[i], signer);
        }
    }

    /**
     * @notice The following functions are inspired by the ERC-7160
     * @notice although they have altered signatures
     * @notice to accommodate `collectionId` and the fact that
     * @notice the pinned tokenURIs are stored in the registry,
     * @notice not in the token contract
     */

    /**
     * @notice Pin a specific token URI
     * @param contractAddress The address of the contract
     * @param tokenId The identifier of the token
     * @param index The index in the URIs array that should be pinned
     */
    function pinTokenURI(
        address contractAddress,
        uint256 tokenId,
        uint32 index
    ) external {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        _pinTokenURI(token, index);
        emit TokenUriPinned(contractAddress, tokenId, index);
    }

    /**
     * @notice Unpin metadata URI for a particular token
     * @param contractAddress The address of the contract
     * @param tokenId The identifier of the token
     */
    function unpinTokenURI(address contractAddress, uint256 tokenId) external {
        bytes32 token = keccak256(abi.encodePacked(contractAddress, tokenId));
        _unpinTokenURI(token);
        emit TokenUriUnpinned(contractAddress, tokenId);
    }
}
