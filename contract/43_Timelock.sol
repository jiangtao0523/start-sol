// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 时间锁合约
contract Timelock {
    
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    event NewAdmin(address indexed newAdmin);

    address public admin;   // 管理员地址
    uint public constant GRACE_PERIOD = 7 days; // 交易有效期，过期的交易作废
    uint public delay;  // 交易锁定时间
    mapping(bytes32 => bool) public queuedTransactions; // 记录所有在时间队列的交易


    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;        
    }

    constructor(uint delay_) {
        delay = delay_;
    }

    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }


    /**
    * 创建交易 并添加到时间锁队列中
    * target: 目标合约地址
    * value: 发送的eth数额
    * signature: 要调用的函数签名
    * data: call data 函数参数
    * executionTime: 交易预计执行的区块链时间戳
    */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns(bytes32) {
        // 预计执行时间需要 >= 区块链时间+延迟时间 比如delay在合约创建时候设置的是120s, 那么executionTime就需要比当前时间戳+delay晚
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // 获取哈希
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 将交易加入到交易队列 
        queuedTransactions[txHash] = true;
        // 触发事件
        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    // 在交易队列中的交易 可以取消
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner {
        // 获取交易hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 交易需要在交易队列中
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: Transaction hasn't been queued.");
        // 移除队列中的未执行的交易
        queuedTransactions[txHash] = false;
        // 触发事件
        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }


    // 执行交易
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns(bytes memory) {
        // 获取交易哈希
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 执行的交易需要在交易队列中且是未取消的
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        // 区块时间需要 >= 预计执行时间
        require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // 区块时间 <= 预计执行 + 交易有效时间
        // 在调用 queueTransaction 函数的时候可预先获取区块时间 将执行时间设置为略大于 刚才获取到的 区块时间+延迟时间. 这样就满足进入队列的条件
        // 过了预计执行时间 还需要手动调用这个函数，但是也不能过太久，最多等待到 预计执行时间+过期时间
        require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        // 移除交易
        queuedTransactions[txHash] = false;
        // 可以通过target.call调用合约函数 参数是函数签名和函数参数的编码
        bytes memory callData;
        if(bytes(signature).length == 0) {
            // 如果没有函数签名 那么函数参数就是data 
            callData = data;
        } else {
            // 如果函数有签名  需要将参数中字符串的签名转成byte4  拼接上函数参数
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 执行交易
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        // 不成功则回滚
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");
        // 触发事件
        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);
        return returnData;
    }


    function getBlockTimestamp() public view returns(uint256) {
        return block.timestamp;
    }
    

    function getTxHash(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public pure returns(bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
}