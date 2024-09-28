// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./32_ERC721.sol";
import "../common/Strings.sol";

/*
    ERC1155 多代币标准
    通常可以通过如果某个代币类型的ID 对应的代币数量大于1 就是同质化代币, 如果某个代币类型ID 对应的代币数量 = 1 可能是非同质化代币
*/

interface IERC1155 is IERC165 {

    // 单类代币转账事件
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    // 多类代币转账事件
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    // accout 账户将所有代币授权给 operator账户 触发的事件
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    // 当id种类的代币URI发生变化的时候触发的事件
    event URI(string value, uint256 indexed id);

    // 查询account账户  id这个种类代币的余额
    function balanceOf(address account, uint256 id) external view returns(uint256);

    // 查询多个账户 对应的 多个不同的代币类型 的余额
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns(uint256[] memory);

    // 将调用者的代币全部授权给 operator地址
    function setApprovalForAll(address operator, bool approved) external;

    // 查询account账户是否将全部代币授权给operator账户
    function isApprovedForAll(address acount, address operator) external view returns(bool);

    // 安全转账 将 amount 个 id类型的代币  从from地址转账给to地址
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    // 批量安全转账 将多个账户 多个不同类型的代币 从from地址转账给to地址
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


interface IERC1155MetadataURI is IERC1155 {
    // 返回id类型的代币 对应的URI
    function uri(uint256 id) external view returns(string memory);
}


interface IERC1155Receiver is IERC165 {
    // operator: 发起转账的合约或者用户
    // from: 代币的归属者
    // id: 代币种类Id
    // value: 代币数量
    // data: 额外的数据字段, 可以包含任意数据
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}


contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {

    using Strings for uint256;
    
    string public name;
    string public symbol;
    // 代币种类 => 地址 => 余额
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // 账户 => 授权账户 => 授权授权
    mapping(address => mapping(address => bool)) _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return
         interfaceId == type(IERC1155).interfaceId || 
         interfaceId == type(IERC1155MetadataURI).interfaceId || 
         interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns(uint256) {
        // 账户地址为0就不查询
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        // 返回id类型的代币 account账户的余额
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) public view virtual override returns(uint256[] memory) {
        // 账户的量和代币种类的量是一致
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        // 构造一个返回值数组  长度是账户数组的长度或者代币种类数组的长度
        uint256[] memory batchBalances = new uint256[](accounts.length);
        // 遍历获取 每个账户需要查询的代币种类对应的余额 并设置到构建的返回值数组中
        for(uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        // 不能给自己授权自己
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        // 在授权映射中维护调用给给operator授权
        _operatorApprovals[msg.sender][operator] = approved;
        // 触发授权事件
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public virtual view override returns(bool){
        // 查询 account 账户是否给 operator账户授权
        return _operatorApprovals[account][operator];
    }

    // 安全转账
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        // 获取调用者
        address operator = msg.sender;
        // 调用者需要是币的拥有者或者授权者
        require(from == operator || isApprovedForAll(from, operator), "ERC1155: caller is not token owner nor approved");
        // 转账地址不能是0
        require(to != address(0), "ERC1155: transfer to the zero address");
        // 获取from账户 id类型的代币的余额
        uint256 fromBalance = _balances[id][from];
        // 余额需要大于转账的数量
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            // 默认情况下  solidity进行算数运算会做溢出检查  消耗gas费用
            // 如果确认不会溢出 可以用unchecked告诉EVM不需要做溢出检查  节省gas
            _balances[id][from] = fromBalance - amount;
        }
        // to账户id类型代币数量增加amount
        _balances[id][to] += amount;

        // 触发单币转账事件
        emit TransferSingle(operator, from, to, id, amount);
        // 检查to账户是否实现接收ERC1155的接口
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    // 多币安全转账
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        // 获取调用者
        address operator = msg.sender;
        // 调用者需要是币的拥有者或者授权者
        require(from == operator || isApprovedForAll(from, operator), "ERC1155: caller is not token owner nor approved");
        // 账户数量和代币种类需要一致
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        // 接收地址不为0
        require(to != address(0), "ERC1155: transfer to the zero address");

        // 遍历转账
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        // 触发多币转账事件
        emit TransferBatch(operator, from, to, ids, amounts);
        // 检查to地址是否实现接收ERC1155的接口
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }


    // 铸造
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        // 铸造地址不为0
        require(to != address(0), "ERC1155: mint to the zero address");
        // 获取调用者
        address operator = msg.sender;

        // 给to账户 id类型的代币数量增加amount个
        _balances[id][to] += amount;
        // 触发单币转账事件
        emit TransferSingle(operator, address(0), to, id, amount);

        // 安全检查
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    // 批量铸造
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        // 铸造地址不为0
        require(to != address(0), "ERC1155: mint to the zero address");
        // 代币种类的数量和账户数量一样
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;
        // 批量铸造
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][to] += amount;
        }

        // 触发批量转账事件
        emit TransferBatch(operator, address(0), to, ids, amounts);
        // 安全检查
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    // 销毁
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        // 销毁的地址不为0
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;
        // 获取销毁地址的id类型代币余额
        uint256 fromBalance = _balances[id][from];
        // 余额要比销毁的数量大
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        // 销毁
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        // 触发单币转账事件
        emit TransferSingle(operator, from, address(0), id, amount);
    }

    // 批量销毁
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        // 销毁的地址不为0
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if(to.code.length > 0) {    // 接收地址是合约
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns(bytes4 response) {
                if(response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }


    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
        if(to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns(bytes4 response) {
                response;
                revert("ERC1155: ERC1155Receiver rejected tokens");
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function uri(uint256 id) public view virtual override returns(string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}

contract BAYC1155 is ERC1155 {

    uint256 constant MAX_ID = 10000; 

    constructor() ERC1155("BAYC1155", "BAYC1155"){}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }  

    function mint(address to, uint256 id, uint256 amount) external {
        // id 不能超过10,000
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        // id 不能超过10,000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }    
}