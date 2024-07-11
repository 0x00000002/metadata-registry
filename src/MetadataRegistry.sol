// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SignersRegister.sol";
import "./AttributesRegister.sol";
import "./ERC7160.sol";

contract MetadataRegistry is AttributesRegister, ERC7160, AccessManaged {
    SignersRegister private _sr;

    constructor(address manager_, address register_) AccessManaged(manager_) {
        _sr = SignersRegister(register_);
    }

    function getAttributesList(
        address tokenContract
    ) public view returns (bytes32[] memory) {
        return _getAttriibuteList[tokenContract];
    }

    function getAttribute(
        bytes32 attrId
    ) public view returns (Attribute memory) {
        return _getAttribute[attrId];
    }

    function getAttributes(
        bytes32[] attrIds
    ) public view returns (Attribute[] memory attrs) {
        Attribute[] memory attrs = new Attribute[](attrIds.length);
        for (uint256 i = 0; i < attrIds.length; i++) {
            attrs[i] = _getAttribute[attrIds[i]];
        }
    }

    /**
     * @notice This function creates a global NFT attribute, with the given URI and name.
     * @param attrs Attributes
     * @return attrIds Array of attribute IDs
     * @dev Can be called only by studios allowed by AccessManager
     */
    function addAttributes(
        address tokenContract, // SFT/NFT collection contract address
        Attribute[] calldata attrs
    ) public restricted returns (bytes32[] memory attrIds) {
        bytes32 studio = _sr.getName(msg.sender);
        attrIds = _addAttributes(studio, attrs);
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
        (
            uint32 collectionId,
            uint32 tokenId,
            bytes32[] memory attrIds,
            uint256[] memory values
        ) = abi.decode(data, (uint32, uint32, bytes32[], uint256[]));

        _setAttributes(tokenId, attrIds, values, signer);
    }

    /**
     * @notice This function sets the value of attribute by the Attribute Owner
     */
    function setAttributes(
        uint256 tokenId,
        bytes32[] calldata attrIds,
        uint256[] calldata values
    ) public restricted {
        _setAttributes(tokenId, attrIds, values, _sr.getSigner(msg.sender));
    }

    /**
     * @notice This function changes the signer of the attribute
     * @param attrIds Array of attribute IDs
     * @param newSigners Array of new signers
     * @dev Can be called only by the MR contract administrator
     */
    function changeAttributeSigner(
        bytes[] calldata attrIds,
        address[] newSigners
    ) public restricted {
        uint256 total = attrIds.length;
        if (attrIds.length != newSigners.length)
            revert(
                InvalidAttributesArrays(
                    ARRAYS_LENGTHS_MISMATCH,
                    total,
                    newSigners.length
                )
            );

        for (uint256 i = 0; i < total; i++) {
            _setAttributeOwner(attrIds[i], newSigners[i]);
        }
    }

    /// @notice Pin a specific token uri for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriPinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @param tokenId The identifier of the nft
    /// @param index The index in the string array returned from the `tokenURIs` function that should be pinned
    function pinTokenURI(uint256 tokenId, uint256 index) external {}

    /// @notice Unpin metadata for a particular token
    /// @dev This call MUST revert if the token does not exist
    /// @dev This call MUST emit a `TokenUriUnpinned` event
    /// @dev This call MAY emit a `MetadataUpdate` event from ERC-4096
    /// @dev It is up to the developer to define what this function does and is intentionally left open-ended
    /// @param tokenId The identifier of the nft
    function unpinTokenURI(uint256 tokenId) external {}
}
