// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISequoiaNFT.sol";
import "./access/Whitelist.sol";

contract SequoiaXUSDMarket is Whitelist, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum SalesStatus {
        DISABLED,
        PRESALE,
        SALE
    }
    struct Token {
        bool resolved;
        uint256 decimals;
    }

    SalesStatus public status;
    uint256 public maxTokenPurchase = 3;

    uint256 public price;

    address public nft;
    address payable public fund;

    mapping(address => Token) public tokens;
    address[] public tokensList;

    event Deposit(address indexed inToken, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);

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

    function mint(uint256 _amount, address _token)
        external
        payable
        isStatus(SalesStatus.SALE)
        isCorrectAmount(_amount)
        isResolvedToken(_token)
        nonReentrant
    {
        _buy(_token, _amount);
    }

    function mintPresale(uint256 _amount, address _token, bytes32[] calldata merkleProof)
        external
        payable
        isNotClaimed
        isStatus(SalesStatus.PRESALE)
        isCorrectAmount(_amount)
        isResolvedToken(_token)
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        nonReentrant
    {
        claimed[msg.sender] = true;
        _buy(_token, _amount);
    }

    function setFund(address payable _newFund) external onlyOwner {
        require(
            _newFund != address(0) && _newFund != address(this),
            "Unacceptable address set"
        );

        fund = _newFund;
    }

    function setStatus(SalesStatus _status) external onlyOwner {
        status = _status;
    }

    // @dev Set NFT basic price in USD (decimals - 0)
    function setPrice(uint256 _usd) external onlyOwner {
        price = _usd;
    }

    // @dev Important: Please use only tokens linked to one currency.
    function addToken(address _token) external onlyOwner {
        require(_token != address(0), "Wrong token");

        uint256 decimals = uint256(IERC20Metadata(_token).decimals());

        Token storage token = tokens[_token];
        token.resolved = true;
        token.decimals = decimals;

        tokensList.push(_token);
    }

    function removeToken(address _token) external onlyOwner {
        require(_token != address(0), "Wrong token");

        address[] memory _tokensList = tokensList;
        uint len = _tokensList.length;

        for (uint i; i < len; i++) {
            if (_tokensList[i] == _token) {
                if (i != len - 1) {
                    tokensList[i] = _tokensList[len - 1];
                }
                tokensList.pop();
            }
        }

        delete tokens[_token];
    }

    function countPurchasePrice(
        address _token,
        uint256 _amount
    ) public view returns (uint256 purchasePrice) {
        purchasePrice = _amount * price * tokens[_token].decimals;
    }

    function getTokensListLength() public view returns (uint256 len) {
        len = tokensList.length;
    }

    function _buy(
        address _token,
        uint256 _amount
    ) internal {
        uint256 deposit = countPurchasePrice(_token, _amount);
        IERC20(_token).safeTransferFrom(msg.sender, fund, deposit);
        ISequoiaNFT(nft).mint(msg.sender, _amount);
        emit Deposit(_token, deposit);
        emit Purchase(msg.sender, _amount);
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

    modifier isResolvedToken(address _token) {
        require(tokens[_token].resolved, "Market: unknown token");
        _;
    }
}