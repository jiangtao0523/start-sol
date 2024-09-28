// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./32_ERC721.sol";

/*
    荷兰拍卖原理：
    1. 拍卖开始时，拍卖方会设置一个较高的初始价格，通常高于商品的实际价值，目的是为了测试市场最高承受能力
    2. 随着事件推移， 如果没有人竞买，拍卖方会按照预先设定的价格递减
    3. 当价格降到某一竞买人认为合理可以接收的范围，该竞买人可以出价，一旦有人出价，拍卖结束，该竞买人可以获得商品
    4. 拍卖在第一个出价的人就结束了，如果没有出价，拍卖会降到一个低价
*/
contract DutchAuction is Ownable, ERC721 {
    // NFT总数
    uint256 public constant COLLECTION_SIZE = 10000;
    // 拍卖的起始价格
    uint256 public constant AUCTION_START_PRICE = 1 ether;
    // 拍卖的最低价格
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    // 拍卖事件
    uint256 public constant AUCTION_TIME = 10 minutes;
    // 降价间隔
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;
    // 每次降价 降多收ETH
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL);

    // 拍卖开始时间
    uint256 public auctionStartTime;
    // metadata URI
    string private _baseTokenURI;
    // 记录所有的tokenId
    uint256[] private _allTokens;

    // 初始化竞拍开始时间是区块的出块时间  后面可以通过函数修改
    constructor() Ownable(msg.sender) ERC721("JT Dutch Auction", "JT Dutch Auction") {
        auctionStartTime = block.timestamp;
    }

    // 获取记录的所有tokenId的数量
    function totalSupply() public view virtual returns(uint256) {
        return _allTokens.length;
    }

    // 添加新的tokenId记录到_allTokens
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

    // 拍卖函数
    function auctionMint(uint256 quantity) external payable {
        // 创建一个拍卖开始时间的本地变量  减少gas消耗
        uint256 _saleStartTime = auctionStartTime;
        // 判断当前时间是否大于竞拍开始时间
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not start yest");
        // 当前记录的token数量+拍卖的数量 < NFT总数
        require(totalSupply() + quantity <= COLLECTION_SIZE, "not enough remaining reserved for auction to support desired mint amount");

        // 计算此次拍卖需要多少ETH
        uint totalCost = getAuctionPrice() * quantity;
        // 判断出价人出的ETH够不够
        require(msg.value >= totalCost, "Need to send more ETH");

        // 如果够的下  将此次的拍卖的所有tokenId都转给出价人 并且及那个所有的tokenId都记录下来
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }

        // 找零给出价人
        if(msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

    } 

    // 计算当前时间的竞拍金额
    function getAuctionPrice() public view returns(uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }
    
    // 设置竞拍的开始时间
    function setAuctionStartTime(uint256 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // 合约的创建者可以体现这个合约的ETH
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }


}