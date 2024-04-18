// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./utils/Errors.sol";
import "./SignersRegister.sol";

contract SignersManaged is Errors, AccessManaged {
    SignersRegister private _register;

    constructor(address manager_) AccessManaged(manager_) {}

    /**
     * @notice Admins can update the SignersRegister contract
     * @param addr The new SignersRegister contract address
     */
    function updateRegister(address addr) external restricted {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _register = new SignersRegister(addr);
    }
}

// TODO  - remove this one after implementing Proxy for SignersRegister
