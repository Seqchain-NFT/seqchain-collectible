// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IAlphaGenRegistry.sol";
import "./access/OperatorAccess.sol";

contract AlphaGenerationRegistry is IAlphaGenRegistry, OperatorAccess {
    mapping(uint256 => Creature) internal _creature;

    function set(uint16 _tokenId, Creature memory _data) external override onlyOperator {
        _creature[_tokenId] = _data;
    }

    function setBatch(uint16[] calldata _ids, Creature[] calldata _data) external override onlyOperator {
        uint len = _ids.length;

        require(len == _data.length, "Registry: _creature length not match");

        for (uint i; i < len; i++) {
            _creature[_ids[i]] = _data[i];
        }
    }

    function get(uint256 _tokenId) external override view returns (Creature memory data) {
        data = _creature[_tokenId];
    }
}