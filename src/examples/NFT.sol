// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4906.sol";

/**
 * @dev FutureverAn example of ERC721 contract
 */
contract NFT is IERC4906, ERC721 {
    constructor(
        string memory token_,
        string memory name_,
        address manager,
        address register
    ) ERC721(name_, token_) {}

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
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
