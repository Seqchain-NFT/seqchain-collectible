// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <1.0.0;

interface IAlphaGenRegistry {
    struct Creature {
        uint8 rarity;
    }

    function set(uint16 _cowId, Creature memory _data) external;

    function setBatch(uint16[] calldata _ids, Creature[] calldata _data) external;

    function get(uint256 _tokenId) external view returns (Creature memory data);
}