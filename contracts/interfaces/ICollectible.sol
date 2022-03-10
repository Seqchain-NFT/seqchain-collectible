// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <1.0.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface ICollectible is IERC721Enumerable {
    function mint(address to, uint256 amount) external;
}