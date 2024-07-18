// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

string constant ATTRIBUTE_EXISTS = "Attribute already exists";
string constant ATTRIBUTE_NOT_EXIST = "Attribute does not exist";
string constant INVALID_NAME = "Invalid attribute name";
string constant ID_VALUES_MISMATCH = "Attr IDs/values length mismatch";
string constant WRONG_ATTRIBUTE_OWNER = "Wrong attribute owner";
string constant ARRAYS_LENGTHS_MISMATCH = "Array lengths mismatch";

contract AttributesRegister {
    /**
     * @notice Each Attribute has its ID,
     * @notice which is different from attribute's `name`
     * @notice to avoid collisions for different collections
     * @dev `name` is bytes32(abi.encodePacked(attributeName::string))
     */
    struct Attribute {
        bytes32 name;
        address signer;
    }

    mapping(bytes32 attrId => Attribute) private _attributes;
    mapping(bytes32 MRTokenId => bytes32[] attrId) private _tokenAttributes;
    mapping(address tokenContract => bytes32[] attrId)
        internal __contractAttributes;
    mapping(bytes32 MRTokenId => mapping(bytes32 attrId => uint256))
        private _values;

    error InvalidAttribute(string errMsg, bytes32 attrId);
    error InvalidAttributesArrays(
        string errMsg,
        uint256 length1,
        uint256 length2
    );

    function _getAttribute(
        bytes32 attrId
    ) internal view returns (Attribute memory) {
        return _attributes[attrId];
    }

    function _getAttributeValue(
        bytes32 MRTokenId,
        bytes32 attrId
    ) internal view returns (uint256) {
        return _values[MRTokenId][attrId];
    }

    function _getAttriibutesList(
        address tokenContract
    ) internal view returns (bytes32[] memory) {
        return __contractAttributes[tokenContract];
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
            if (_attributes[id].signer > address(0))
                revert InvalidAttribute(ATTRIBUTE_EXISTS, id);

            _attributes[id] = attrs[i];
            attrIds[i] = id;
            names[i] = attrs[i].name;
            __contractAttributes[tokenContract].push(id);
        }

        return attrIds;
    }

    function _setAttribute(
        bytes32 MRTokenId,
        bytes32 attrId,
        uint256 value,
        address signer
    ) internal {
        if (_attributes[attrId].signer == signer) {
            if (_values[MRTokenId][attrId] == 0) {
                _tokenAttributes[MRTokenId].push(attrId);
            }
            _values[MRTokenId][attrId] = value;
        } else {
            revert InvalidAttribute(ATTRIBUTE_NOT_EXIST, attrId);
        }
    }

    function _setAttributeOwner(bytes32 attrId, address newSigner) internal {
        if (_attributes[attrId].signer > address(0))
            _attributes[attrId].signer = newSigner;
        else {
            revert InvalidAttribute(ATTRIBUTE_NOT_EXIST, attrId);
        }
    }
}
