// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

string constant ATTRIBUTE_EXISTS = "Attribute already exists";
string constant ATTRIBUTE_NOT_EXIST = "Attribute does not exist";
string constant INVALID_NAME = "Invalid attribute name";
string constant ID_VALUES_MISMATCH = "Attr IDs/values length mismatch";
string constant WRONG_ATTRIBUTE_OWNER = "Wrong attribute owner";
string constant ARRAYS_LENGTHS_MISMATCH = "Array lengths mismatch";

error InvalidAttribute(string errMsg, bytes32 attrId);
error InvalidAttributesArrays(string errMsg, uint256 length1, uint256 length2);
error NonExistingAttribute(string errMsg, bytes32 attrId, uint256 idx);

contract AttributesRegister {
    /**
     * @notice Each Attribute has its ID,
     * @notice which is different from attribute's `name`
     * @notice to avoid collisions for different collections
     * @dev `name` is bytes32(abi.encodePacked(attributeName::string))
     * @dev ID is keccak256(abi.encodePacked(tokenContract, name))
     */
    struct Attribute {
        bytes32 name;
        uint256 value;
        address signer;
    }

    mapping(bytes32 attrId => Attribute) private _attribute;
    mapping(address tokenContract => bytes32[]) private _tokenAttributes;

    event AttributesAdded(
        address indexed tokenContract,
        bytes32[] attrNames,
        bytes32[] attrIds
    );
    event AttributesUpdated(
        address indexed tokenContract,
        uint32 indexed tokenId,
        bytes32[] indexed attrIds,
        uint256[] attrValues
    );

    function _getAttribute(
        bytes32 attrId
    ) internal view returns (Attribute memory) {
        return _attribute[attrId];
    }

    function _getAttriibuteList(
        address tokenContract
    ) internal view returns (bytes32[] memory) {
        return _tokenAttributes[tokenContract];
    }

    /**
     * @notice This function adds attributes to the contract
     * @notice Attributes should contain unique names,
     * @param tokenContract Address of the token contract
     * @param attrs Array of attributes to create
     */
    function _addAttributes(
        address tokenContract,
        Attribute[] memory attrs
    ) internal returns (bytes32[] memory) {
        uint256 total = attrs.length;

        bytes32[] memory attrIds = new bytes32[](total);
        bytes32[] memory names = new bytes32[](total);

        for (uint256 i = 0; i < total; i++) {
            bytes32 id = keccak256(
                abi.encodePacked(tokenContract, attrs[i].name)
            );

            if (attrs[i].name.length < 1)
                revert InvalidAttribute(INVALID_NAME, id);
            if (_attribute[id].signer > address(0))
                revert InvalidAttribute(ATTRIBUTE_EXISTS, id);

            _attribute[id] = attrs[i];
            attrIds[i] = id;
            names[i] = attrs[i].name;
            _tokenAttributes[tokenContract].push(id);
        }

        emit AttributesAdded(tokenContract, names, attrIds);
        return attrIds;
    }

    function _setAttributes(
        address tokenContract,
        uint32 tokenId,
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
            bytes32 id = attrIds[i];

            if (id == bytes32(0))
                revert NonExistingAttribute(ATTRIBUTE_NOT_EXIST, id, i);
            if (_attribute[id].signer != signer)
                revert InvalidAttribute(WRONG_ATTRIBUTE_OWNER, id);

            _attribute[id] = Attribute({
                name: _attribute[id].name,
                value: values[i],
                signer: signer
            });
        }

        emit AttributesUpdated(tokenContract, tokenId, attrIds, values);
    }

    function _setAttributeOwner(bytes32 attrId, address newSigner) internal {
        if (_attribute[attrId].signer > address(0))
            _attribute[attrId].signer = newSigner;
        else {
            revert NonExistingAttribute(ATTRIBUTE_NOT_EXIST, attrId, 0);
        }
    }
}
