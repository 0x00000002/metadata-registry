// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @dev Futureverse - Errors definition contract
 */
string constant UNKNOWN_SIGNER = "Unknown signer";
string constant INVALID_ADDRESS = "Invalid address";
string constant INVALID_URI = "Invalid URI";
string constant INVALID_NAME = "Invalid attribute name";
string constant ID_VALUES_MISMATCH = "Attr IDs/values length mismatch";
string constant WRONG_OWNER = "Wrong owner";

contract Errors {
    error InvalidInput(string errMsg);
    error EmptyURI(string errMsg, uint256 idx);
    error InvalidArrays(string errMsg, uint256 l1, uint256 l2);
    error InvalidAttribute(string errMsg, bytes32 uri);
}
