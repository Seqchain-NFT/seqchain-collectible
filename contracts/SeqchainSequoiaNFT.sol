// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721Enumerable, ERC721, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/ISequoiaNFT.sol";
import "./access/OperatorAccess.sol";
import "./libs/BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title SeqchainSequoiaNFT - General Seqchain NFT collection.
 * 1000
 */
contract SeqchainSequoiaNFT is ISequoiaNFT, ERC721Enumerable, OperatorAccess {
    using Strings for uint256;

    uint256 public initDate;
    uint256 public tokenIdTracker;

    string internal _baseUri;

    /**
     * @dev Preset the values NFT token.
     * See {ERC721-constructor}.
     */
    constructor()
        ERC721("Seqchain Sequoia NFT", "SEQNFT")
    {
        initDate = block.timestamp;
    }

    /**
     * @dev Mint NFTs token to specific address `_to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address _to, uint256 _amount) external override onlyOperator {
        uint256 tokenId = tokenIdTracker;

        require(tokenId + _amount < _countMaxSupply(), "Max supply reached");

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

    function maxSupply() external view returns (uint supply) {
        supply = _countMaxSupply();
    }

    function lastUnlock() external view returns (uint unlockedAt) {
        uint256 _initDate = initDate;
        uint256 yearsLeft = BokkyPooBahsDateTimeLibrary.diffYears(_initDate, block.timestamp);

        if (yearsLeft < 2) {
            unlockedAt = _initDate;
        } else {
            uint256 addYears = (yearsLeft % 2 != 0) ? (yearsLeft - 1) : yearsLeft - 2;
            unlockedAt = BokkyPooBahsDateTimeLibrary.addYears(_initDate, addYears);
        }
    }

    function nextUnlock() external view returns (uint unlockAt) {
        uint256 _initDate = initDate;
        uint256 yearsLeft = BokkyPooBahsDateTimeLibrary.diffYears(_initDate, block.timestamp);

        if (yearsLeft < 2) {
            unlockAt = _initDate;
        } else {
            uint256 addYears = (yearsLeft % 2 != 0) ? (yearsLeft + 1) : yearsLeft + 2;
            unlockAt = BokkyPooBahsDateTimeLibrary.addYears(_initDate, addYears);
        }
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

    function _countMaxSupply() internal view returns (uint supply) {
        uint256 initAmount = 1000;
        uint256 yearsLeft = BokkyPooBahsDateTimeLibrary.diffYears(initDate, block.timestamp);

        if (yearsLeft < 2) {
            supply = initAmount;
        } else {
            supply = initAmount + initAmount * (
                (yearsLeft % 2 != 0) ? (yearsLeft - 1) : yearsLeft
            );
        }
    }
}
