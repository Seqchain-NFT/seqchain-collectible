// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAlphaGenRegistry.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/IFungibleToken.sol";
import "./libs/UintArrayUtils.sol";

contract FarmingNFT is ERC721Holder, Ownable {
    using SafeERC20 for IFungibleToken;

    IAlphaGenRegistry public registry;
    ICollectible public nft;
    IFungibleToken public token;

    address public feeTo;
    uint256 public feeInterest = 300; // decimal 10000, default - 3%

    // token id -> block
    mapping (uint256 => uint256) public lastReward;
    // rarity level -> tokens
    mapping (uint256 => uint256) public rewardsPerBlock;

    event FeeInterestSet(uint256 interest);
    event FeeToSet(address recipient);
    event RewardSet(uint256 rarity, uint256 reward);
    event FarmingActivated(uint256 tokenId);

    constructor(
        IAlphaGenRegistry _registry,
        ICollectible _nft,
        IFungibleToken _token,
        uint256 blocksPerDay,
        uint256[] memory _dailyRewards
    ) {
        registry = _registry;
        nft = _nft;
        token = _token;

        for (uint i; i < _dailyRewards.length; i++) {
            rewardsPerBlock[i + 1] = countBlockReward(_dailyRewards[i], blocksPerDay);
        }
    }

    function enable(uint256[] calldata _tokenIDs) external {
        require(
            !UintArrayUtils.hasDuplicate(_tokenIDs),
            "Duplicates in token list"
        );

        uint256 len = _tokenIDs.length;

        uint256 i;
        for (i; i < len; i++) {
            require(
                nft.ownerOf(_tokenIDs[i]) != msg.sender,
                "Ownership not approved"
            );
        }

        i = 0;
        for (i; i < len; i++) {
            if (lastReward[_tokenIDs[i]] == 0) {
                lastReward[_tokenIDs[i]] = block.number;
                emit FarmingActivated(_tokenIDs[i]);
            }
        }
    }

    function earn(uint256 _tokenId) external {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "Ownership not approved"
        );

        uint256 reward = pendingReward(_tokenId);
        if (reward > 0) {
            lastReward[_tokenId] = block.number;
            token.mint(feeTo, reward * feeInterest / 10000); // dev reward
            token.mint(msg.sender, reward);
        }
    }

    function earnBatch(uint256[] calldata _tokenIDs) external {
        require(
            !UintArrayUtils.hasDuplicate(_tokenIDs),
            "Duplicates in token list"
        );

        IAlphaGenRegistry.Creature memory _data;

        uint256 len = _tokenIDs.length;

        require(len >= 2, "Lower threshold exceeded");

        uint256 i;
        for (i; i < len; i++) {
            if (nft.ownerOf(_tokenIDs[i]) != msg.sender) {
                revert("Ownership not approved");
            }

            _data = registry.get(_tokenIDs[i]);
        }

        uint256 reward = pendingRewardBatch(_tokenIDs);
        i = 0;
        for (i; i < len; i++) {
            lastReward[_tokenIDs[i]] = block.number;
        }

        if (reward > 0) {
            token.mint(feeTo, reward * feeInterest / 10000);
            token.mint(msg.sender, reward);
        }
    }

    function pendingReward(uint256 _tokenId)
        public
        view
        returns (uint256 reward)
    {
        IAlphaGenRegistry.Creature memory _data = registry.get(_tokenId);

        uint256 lastRewardAt = lastReward[_tokenId];
        uint256 blockDiff;
        if (lastRewardAt != 0) {
            blockDiff = block.number - lastRewardAt;
            reward = rewardsPerBlock[_data.rarity] * blockDiff;
        }
    }

    function pendingRewardBatch(uint256[] memory _tokenIds)
        public
        view
        returns (uint256 reward)
    {
        IAlphaGenRegistry.Creature memory _data;

        uint256 len = _tokenIds.length;
        uint256 lastRewardAt;
        for (uint i; i < len; i++) {
            _data = registry.get(_tokenIds[i]);
            lastRewardAt = lastReward[_tokenIds[i]];
            if (lastRewardAt != 0) {
                reward += rewardsPerBlock[_data.rarity] * (block.number - lastRewardAt);
            }
        }
    }

    function setFeeInterest(uint256 _value) external onlyOwner {
        require(_value <= 10000/2, "Wrong percent set");

        feeInterest = _value;
        emit FeeInterestSet(_value);
    }

    function setFeeTo(address _account) external onlyOwner {
        require(_account != address(0), "Zero address set");

        feeTo = _account;
        emit FeeToSet(_account);
    }

    function setReward(uint256 _rarity, uint256 _reward) external onlyOwner {
        rewardsPerBlock[_rarity] = _reward;
        emit RewardSet(_rarity, _reward);
    }

    function countBlockReward(uint256 _weis, uint256 _blocks)
        public
        pure
        returns (uint256 reward)
    {
        reward = _weis / _blocks;
    }
}