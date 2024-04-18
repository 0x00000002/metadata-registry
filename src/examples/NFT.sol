// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "../DynamicMetadata.sol";
import "../utils/Errors.sol";

/**
 * @dev Futureverse Swappable - An example of ERC721 IMintable contract
 */
contract NFT is ERC721, AccessManaged {
    constructor(
        string memory token_,
        string memory name_,
        address manager
    ) ERC721(name_, token_) AccessManaged(manager) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice mint() function EXAMPLEs
     * @param receiver - address of the wallet to receive new token
     * @param tokenId - token ID to mint (optional, if minting is sequential)
     */

    function mint(address receiver, uint256 tokenId) public {
        _mint(receiver, tokenId);
    }

    /**
     * @notice Optional burn() functioт - EXAMPLE for testing purpose
     * @param tokenId The token ID to burn
     */
    function burn(uint256 tokenId) external restricted {
        _burn(tokenId);
    }
}
