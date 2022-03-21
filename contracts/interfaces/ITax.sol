// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITax {
    function fee() external view returns (uint256);

    function setFeeLimit(uint256 percent) external;
}