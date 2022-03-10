// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Source code COPIED and MODIFIED: https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

library UintArrayUtils {

    /**
     * Returns whether or not there's a duplicate. Runs in O(n^2).
     * @param _collection Array to search
   * @return Returns true if duplicate, false otherwise
   */
    function hasDuplicate(uint256[] calldata _collection) internal pure returns (bool) {
        uint256 len = _collection.length;
        if (len == 0) {
            return false;
        }
        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = i + 1; j < len; j++) {
                if (_collection[i] == _collection[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}