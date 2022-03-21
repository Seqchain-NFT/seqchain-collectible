// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./interfaces/ISequoiaNFT.sol";
import "./Tax.sol";

contract SequoiaSeedlingMarket is ReentrancyGuard, SendValueWithFallbackWithdraw, Tax {
    address public nft;
    uint256 public price = 1e18;

    mapping(uint => uint) public ancestors;
    mapping(uint => uint[]) public descendants;

    constructor(
        address _nft,
        address payable _fund
    ) {
        require(
            _nft != address(0) &&
            _fund != address(0),
            "Unacceptable address set"
        );

        nft = _nft;
        fund = _fund;
    }

    function grow(uint256 _ancestorId)
        external
        payable
        nonReentrant
    {
        uint256 deposit = msg.value;

        require(
            price == deposit,
            "Market: ether value sent is not correct"
        );
        require(descendants[_ancestorId].length < 2, "Max descendants reached!");

        if (fee > 0) {
            // to nft holder
            address royaltyRecipient = IERC721(nft).ownerOf(_ancestorId);
            uint256 royalty = fee * deposit / DECIMAL;
            _sendValueWithFallbackWithdraw(royaltyRecipient, royalty);

            // to service
            Address.sendValue(fund, deposit - royalty);
        } else {
            // to service
            Address.sendValue(fund, deposit);
        }

        // mint NFT
        ISequoiaNFT(nft).mint(msg.sender, 1);

        uint256 descendantId = IERC721Enumerable(nft).totalSupply();
        descendants[_ancestorId].push(descendantId);
        ancestors[descendantId] = _ancestorId;
    }

    function growBatch(uint256[] calldata _ancestorIds) external payable nonReentrant {
        uint256 amount = _ancestorIds.length;

        require(
            price * amount == msg.value,
            "Market: ether value sent is not correct"
        );

        uint256 descendantId = IERC721Enumerable(nft).totalSupply();
        uint256 toService;
        for (uint i; i < amount; i++) {
            require(descendants[_ancestorIds[i]].length < 2, "Max descendants reached!");

            if (fee > 0) {
                // to nft holder
                address royaltyRecipient = IERC721(nft).ownerOf(_ancestorIds[i]);
                uint256 royalty = fee * price / DECIMAL;
                _sendValueWithFallbackWithdraw(royaltyRecipient, royalty);

                // to service
                toService += price - royalty;
            } else {
                // to service
                toService += price;
            }

            if (i == 0) {
                descendantId = IERC721Enumerable(nft).totalSupply();
            } else {
                descendantId += i;
            }

            descendants[_ancestorIds[i]].push(descendantId);
            ancestors[descendantId] = _ancestorIds[i];
        }

        Address.sendValue(fund, toService);

        // mint NFT
        ISequoiaNFT(nft).mint(msg.sender, amount);
    }

    function setPrice(uint256 _priceWei) external onlyOwner {
        require(_priceWei != 0, "Zero price set");

        price = _priceWei;
    }
}