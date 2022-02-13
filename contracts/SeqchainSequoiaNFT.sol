// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721Enumerable, ERC721, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/ISequoiaNFT.sol";
import "./access/OperatorAccess.sol";

/**
 * @title SeqchainSequoiaNFT - General Seqchain NFT collection.
 * 1000
 */
contract SeqchainSequoiaNFT is ISequoiaNFT, ERC721Enumerable, OperatorAccess {
    using Strings for uint256;

    uint256 public tokenIdTracker;

    string internal _baseUri;

    /**
     * @dev Preset the values NFT token.
     * See {ERC721-constructor}.
     */
    constructor()
        ERC721("Seqchain Sequoia NFT", "SEQNFT")
    {}

    /**
     * @dev Mint NFTs token to specific address `_to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address _to, uint256 _amount) external override onlyOperator {
        uint256 tokenId = tokenIdTracker;
        for (uint i; i < _amount; i++) {
            _mint(_to, tokenId + i);
        }

        tokenIdTracker = tokenId + _amount;
    }

    /**
     * @dev See {ERC71-_setBaseURI}.
     */
    function setBaseURI(string memory _uri) public onlyOwner {
        _baseUri = _uri;
    }

    /**
     * @dev See {ERC71-_exists}.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseUri).length > 0
                ? string(abi.encodePacked(_baseUri, (_tokenId).toString()))
                : "";
    }
}
