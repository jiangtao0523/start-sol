// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721, IERC721Receiver, JTApe} from "./32_ERC721.sol";

contract NFTSwap is IERC721Receiver {
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);

    struct Order {
        address owner;
        uint256 price;
    }

    // nft地址 -> tokenId -> (owner, price)
    mapping(address => mapping(uint256 => Order)) public nftList;

    fallback() external payable {}

    receive() external payable {}

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns(bytes4) {
        // 未使用  防止告警  
        operator; 
        from; 
        tokenId; 
        data;
        // 返回选择器
        return IERC721Receiver.onERC721Received.selector;
    }

    // 卖家NFT上架 
    function list(address _nftAddress, uint256 _tokenId, uint256 _price) public {
        // 利用合约地址声明合约变量
        IERC721 _nft = IERC721(_nftAddress);
        // 代币需要授权给当前交易所合约
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval");
        // 价格需要>0
        require(_price > 0);

        // 创建一个Order对象
        Order storage _order = nftList[_nftAddress][_tokenId];
        // 设置Order对象的owner是当前调用者
        _order.owner = msg.sender;
        // 设置价格
        _order.price = _price;

        // 将代币转给交易所(转给交易所之前需要先给交易所授权)
        _nft.safeTransferFrom(msg.sender, address(this),  _tokenId);

        // 触发上架时间
        emit List(msg.sender, _nftAddress, _tokenId, _price);
    }

    
    // 购买NFT
    function purchase(address _nftAddress, uint256 _tokenId) public payable {
        // 从nft地址 + tokenId 从列表获取Order对象
        Order storage _order = nftList[_nftAddress][_tokenId];
        // order对应的price应该 > 0
        require(_order.price > 0, "Invalid Price");
        // 买家出价应该大于代币的价格
        require(msg.value >= _order.price, "Increase Price");

        // 根据合约地址创建合约对象
        IERC721 _nft = IERC721(_nftAddress);
        // 判断代币是否归属于交易所合约
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");
        // 将代币转给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        
        // 给卖家转账 金额是卖家的上架金额
        payable(_order.owner).transfer(_order.price);
        // 给买家找零
        payable(msg.sender).transfer(msg.value - _order.price);

        // 删除列表中的订单对象
        delete nftList[_nftAddress][_tokenId];

        // 触发购买事件
        emit Purchase(msg.sender, _nftAddress, _tokenId, _order.price);
    }


    // 下架
    function revoke(address _nftAddress, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddress][_tokenId];
        // 需要是代币的归属者才可以下架
        require(_order.owner == msg.sender, "Not Owner");

        IERC721 _nft = IERC721(_nftAddress);
        // 下架的代币需要已经在交易所上架过的
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT在合约中

        // 将代币转给卖家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddress][_tokenId]; // 删除order

        // 触发下架事件
        emit Revoke(msg.sender, _nftAddress, _tokenId);
    }

    
    // 更新价格
    function update(address _nftAddress, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT价格大于0
        Order storage _order = nftList[_nftAddress][_tokenId];
        require(_order.owner == msg.sender, "Not Owner");   // 调用这个需要是代币的owner

        IERC721 _nft = IERC721(_nftAddress);
        // 更新价格的代币需要在交易所上架过
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        // 更新价格
        _order.price = _newPrice;
        // 触发更新价格事件
        emit Update(msg.sender, _nftAddress, _tokenId, _newPrice);
    }
}