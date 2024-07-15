// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/utils/math/Math.sol";

bytes16 constant HEX_DIGITS = "0123456789abcdef";

library StringUtils {
    function toUpperHexString(
        uint256 value
    ) internal pure returns (string memory) {
        uint256 length = Math.log256(value) + 1;
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length);

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        require(localValue == 0, "HexConversion: value overflow");

        return toUppercase(string(buffer));
    }

    function toUppercase(
        string memory inputNonModifiable
    ) internal pure returns (string memory) {
        bytes memory bytesInput = _copyBytes(bytes(inputNonModifiable));

        for (uint i = 0; i < bytesInput.length; i++) {
            // checks for valid ascii characters // will allow unicode after building a string library
            require(
                uint8(bytesInput[i]) > 31 && uint8(bytesInput[i]) < 127,
                "Only ASCII characters"
            );
            // lowercase character...
            if (uint8(bytesInput[i]) > 96 && uint8(bytesInput[i]) < 123) {
                // subtract 32 to make it uppercase
                bytesInput[i] = bytes1(uint8(bytesInput[i]) - 32);
            }
        }
        return string(bytesInput);
    }

    function _copyBytes(
        bytes memory _bytes
    ) private pure returns (bytes memory) {
        bytes memory copy = new bytes(_bytes.length);
        uint256 max = _bytes.length + 31;
        for (uint256 i = 32; i <= max; i += 32) {
            assembly {
                mstore(add(copy, i), mload(add(_bytes, i)))
            }
        }
        return copy;
    }
}
