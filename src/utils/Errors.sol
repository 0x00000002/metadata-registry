// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @dev Futureverse - Errors definition contract
 */
string constant UNKNOWN_SIGNER = "Unknown signer";
string constant UNKNOWN_MANAGER = "Invalid manager";
string constant INVALID_ADDRESS = "Invalid address";
string constant ID_IS_TAKEN = "ID already exists";
string constant ID_DOES_NOT_EXIST = "ID does not exist";
string constant STUDIO_EXISTS = "Studio exist";

string constant INVALID_NAME = "Invalid attribute name";
string constant ID_VALUES_MISMATCH = "Attr IDs/values length mismatch";
string constant WRONG_ATTRIBUTE_OWNER = "Wrong attribute owner";

contract Errors {
    error InvalidInput(string errMsg);
    error InvalidArrays(string errMsg, uint256 l1, uint256 l2);
    error InvalidAttribute(string errMsg, bytes32 uri);
    error NonExistingAttribute(string errMsg, bytes32 uri, uint256 idx);
}
