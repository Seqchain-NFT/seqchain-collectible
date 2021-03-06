// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISequoiaNFT.sol";
import "./access/Whitelist.sol";

contract SequoiaMarket is Whitelist, ReentrancyGuard {
    enum SalesStatus {
        DISABLED,
        PRESALE,
        SALE
    }

    SalesStatus public status;
    uint256 public maxTokenPurchase = 1;

    address public nft;
    address payable public fund;
    uint256 public price = 1e18;

    event Purchase(address indexed buyer, uint256 indexed amount, uint256 paid);
    event FundSet(address payable account);
    event PriceSet(uint256 price);
    event StatusSet(SalesStatus status);
    event MaxTokenPurchaseSet(uint256 amount);

    constructor(
        address _nft,
        address payable _fund
    ) {
        require(
            address(_nft) != address(0) &&
            address(_fund) != address(0),
            "Unacceptable address set"
        );

        nft = _nft;
        fund = _fund;
    }

    receive()
        external
        payable
        isStatus(SalesStatus.SALE)
        nonReentrant
    {
        _buy(msg.value / price, msg.value);
    }

    function mint(uint256 _amount)
        external
        payable
        isStatus(SalesStatus.SALE)
        isCorrectAmount(_amount)
        nonReentrant
    {
        _buy(_amount, msg.value);
    }

    function mintPresale(uint256 _amount, bytes32[] calldata merkleProof)
        external
        payable
        isStatus(SalesStatus.PRESALE)
        isCorrectAmount(_amount)
        isNotClaimed
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        nonReentrant
    {
        claimed[msg.sender] = true;
        _buy(_amount, msg.value);
    }

    function setFund(address payable _newFund) external onlyOwner {
        require(
            _newFund != address(0) && _newFund != address(this),
            "Unacceptable address set"
        );

        fund = _newFund;
        emit FundSet(_newFund);
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price != 0, "Incorrect price");

        price = _price;
        emit PriceSet(_price);
    }

    function setStatus(SalesStatus _status) external onlyOwner {
        status = _status;
        emit StatusSet(_status);
    }

    function setMaxTokenPurchase(uint256 _amount) external onlyOwner {
        require(_amount != 0, "Incorrect amount");

        maxTokenPurchase = _amount;
        emit MaxTokenPurchaseSet(_amount);
    }

    function _buy(
        uint256 _amount,
        uint256 _deposit
    ) internal {
        require(
            price * _amount == _deposit,
            "Market: ether value sent is not correct"
        );

        Address.sendValue(fund, _deposit);
        ISequoiaNFT(nft).mint(msg.sender, _amount);
        emit Purchase(msg.sender, _amount, _deposit);
    }

    modifier isCorrectAmount(uint256 _amount) {
        require(
            _amount != 0 && _amount <= maxTokenPurchase,
            "Market: invalid amount set, to much or too low"
        );
        _;
    }

    modifier isStatus(SalesStatus _status) {
        require(status == _status, "Market: incorrect status");
        _;
    }
}