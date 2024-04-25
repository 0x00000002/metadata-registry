// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "../MultipleURIs.sol";
import "../DynamicAttributes.sol";
import "../utils/Errors.sol";

// import "forge-std/console.sol";

/**
 * @dev Futureverse Swappable - An example of ERC721 IMintable contract
 */
contract NFT is ERC721, MultipleURIs, DynamicAttributes {
    constructor(
        string memory token_,
        string memory name_,
        address manager,
        address register
    )
        ERC721(name_, token_)
        DynamicAttributes(manager, register)
        MultipleURIs(register)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, MultipleURIs) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
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
