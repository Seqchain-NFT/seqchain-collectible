// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITax.sol";

abstract contract Tax is ITax, Ownable {
    uint256 public constant DECIMAL = 10_000;
    uint256 public override fee;

    address payable public fund;

    event FeeLimitSet(uint256 percent);

    constructor() {
        fee = 1500; // 15%
    }

    function setFeeLimit(uint256 _percent) external override onlyOwner {
        require(_percent <= 5_000, "No more then 50%");
        fee = _percent;
        emit FeeLimitSet(_percent);
    }

    function setFund(address payable _fund) external onlyOwner {
        require(
            _fund != address(0) && _fund != address(this),
            "Unacceptable address set"
        );

        fund = _fund;
    }
}