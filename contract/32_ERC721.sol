// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../common/Strings.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);

    function ownerOf(uint256 tokenId) external view returns(address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns(address operator);

    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

interface IERC721Metadata {
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}


contract ERC721 is IERC721, IERC721Metadata {
    // 非同质化代币就是每个代币的价值是不一样的。比特币和以太币等都是同质化代币。这个合约说到的代币都是非同质化代币

    // uint256这个类型的变量可以调用String.sol中的方法
    using Strings for uint256;
    // 非同质化代币的名称
    string public override name;
    // 非同质化代币的符号
    string public override symbol;
    // tokenId对应的拥有者的地址映射
    mapping(uint256 => address) private _owners;
    // 代币拥有者所持有的代币数量映射
    mapping(address => uint256) private _balances;
    // tokenId到授权地址的映射
    mapping(uint256 => address) private _tokenApprovals;
    // 拥有者到 操作者的批量授权映射(可以理解为操作者有拥有者所有代币的交易权限)
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // 无效的接收者
    error ERC721InvalidReceiver(address receiver);
    // 初始化同质化代币名称和同质化代币符号
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // 实现IERC165接口函数  实现这个合约来声明支持ERC721或者ERC155
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // 用来查询owner地址的代币的数量
    function balanceOf(address owner) external view override returns(uint256) {
        // 检查owner地址是不是0 
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // 查询某个代币的owner
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        // 如果给的tokenId没有查询到owner 会得到0的地址  抛出异常
        require(owner != address(0), "token doesn't exist");
    }

    // 判断是否owner是否批量授权给operator 交易代币
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 将所持有的代币全部授权给operator approved = true
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 查询tokenId 的授权地址
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 私有的代币授权逻辑  将owner的某个代币授权给to地址
    function _approve(address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }    

    // 实现ERC721接口的授权方法 将某个代币授权给某个地址
    function approve(address to, uint tokenId) external override {
        // 会先根据tokenId获取owner
        address owner = _owners[tokenId];
        require(
            // 再判断调用者是不是这个owner 或者 owner是不是授权给了这个调用者。只有这样才有权限授权给其他地址
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        // 调用私有授权方法
        _approve(owner, to, tokenId);
    }    

    // 私有的，查询 spender地址是否可以使用tokenId（需要是owner或被授权地址）
    function _isApprovedOrOwner(address owner, address spender, uint tokenId) private view returns (bool) {
        // 调用这个方法有一个必要条件  tokenId是owner地址拥有的
        return (spender == owner || // 如果spender 就是 owner 则可以使用
            _tokenApprovals[tokenId] == spender ||  // 如果这个tokenId授权给了spender 则可以使用
            _operatorApprovals[owner][spender]);    // 如果owner授权的所有代币给spender 则也可以使用
    }    

    // 转账函数 通过调整_balances和owner变量 将tokenId从from转给to
    // 需要两个条件 1. tokenId被from拥有 2. to不是0地址
    function _transfer(address owner, address from, address to, uint tokenId) private {
        // from需要是tokenId的owner
        require(from == owner, "not owner");
        // to不是0地址
        require(to != address(0), "transfer to the zero address");
        // 将tokenId从owner授权给0地址  主要是失效掉之前owner对tokenId的授权
        _approve(owner, address(0), tokenId);

        // from地址的代币数量-1
        _balances[from] -= 1;
        // to地址的代币数量+1
        _balances[to] += 1;
        // tokenId归属于to地址
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }    

    // 实现ERC721的转账函数 调用私有的转账函数。 非安全转账，接收者可能将代币永久锁定无法使用
    function transferFrom(address from, address to, uint tokenId) external override {
        // 先获取tokenId的owner地址
        address owner = ownerOf(tokenId);
        require(
            // 需要有tokenId的使用权
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        // 实现转账
        _transfer(owner, from, to, tokenId);
    }    

    // 私有的安全转账  调用完私有的转账函数之后 会判断接收者是否是有效的 如果无效回滚交易
    function _safeTransfer(address owner, address from, address to, uint tokenId, bytes memory _data) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    // 安全转账  主要是差距是调用的是私有的安全转账函数
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    // 安全转账重载函数
    function safeTransferFrom(address from, address to, uint tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 铸造函数 给to地址产生一个tokenId 的代币
    function _mint(address to, uint tokenId) internal virtual {
        // to不是0地址
        require(to != address(0), "mint to zero address");
        // 代币不存在
        require(_owners[tokenId] == address(0), "token already minted");

        // to地址代币数量+1
        _balances[to] += 1;
        // 代币tokenId 归属于to
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // 销毁代币 
    function _burn(uint tokenId) internal virtual {
        // 获取tokenId的owner
        address owner = ownerOf(tokenId);
        // 判断销毁者是不是代币的拥有者
        require(msg.sender == owner, "not owner of token");
        // 将tokenId的授权置为无效  其实就是将tokenId授权地址设置为0地址
        _approve(owner, address(0), tokenId);
        // owner的代币数量-1
        _balances[owner] -= 1;
        // 删除tokenId到owner的映射
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // 实现IERC721Metadata的tokenURI函数，查询metadata。
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // 计算{tokenURI}的BaseURI，tokenURI就是把baseURI和tokenId拼接在一起，需要开发重写。
    // BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    // 用于在 to 为合约的时候调用IERC721Receiver-onERC721Received, 以防 tokenId 被不小心转入黑洞
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {   // 如果to地址的code有值  说明to地址是一个合约
            // 捕获 使用to地址创建接收者合约实例在调用onERC721Received方法时候可能发生的异常
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                // 如果 onERC721Received 函数的 返回值是这个函数的选择器的时候 回滚交易
                // 这个返回值是一个约定 如果调用成功需要给这个返回值设置为这个函数的选择器 否则交易会回滚
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) { 
                // 如果返回值是一个空的字节数组 则也回滚交易
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    // @solidity memory-safe-assembly
                    // 也是回滚交易 同时抛出接收者给的错误原因
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

contract JTApe is ERC721 {
    uint public MAX_APES = 10000;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function _baseURI() internal pure override returns(string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address to, uint tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES, "tokenId out of range");
        _mint(to, tokenId);
    }
}
