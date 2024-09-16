// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DataStorageAndScope {
    // ------------------------------------------------------------------ 作用域 ---------------------------------
    /*
        三种作用域:
        1. 状态变量: 数据存储在链上, 所有合约内函数都可以访问, gas消耗高, 在合约内,函数外声明
        2. 局部变量: 仅在函数执行过程中有效的变量, 函数退出后, 变量无效. 局部变量的数据存储在内存里, 不上链, gas消耗低
        3. 全局变量: solidity预留的关键字, 可以不声明直接使用
    */

    // 状态变量
    uint public a = 1;
    uint public b;
    string public c;
    // 可以在函数中更改状态变量的值
    function foo() external {
        a = 2;
        b = 3;
        c = "a";
    }

    // 局部变量
    function bar() external pure returns(uint) {
        uint d = 1;
        uint e = 2;
        uint f = d + e;
        return f;
    }


    // 全局变量
    function globalVariable() external payable returns(address, uint, bytes memory) {
        // 请求发起地址, 可能是一个账户地址 可能是一个合约地址
        address sender = msg.sender;
        // 区块高度
        uint blockNum = block.number;
        // 区块数据 是一个字节数组
        bytes memory data = msg.data;

        // 扩展一些常用的全局变量
        // 当前区块矿工地址 address payable
        block.coinbase;
        // 当前区块的gaslimit uint
        block.gaslimit;
        // 指定区块的哈希 仅可用于最近的256个区块 且不包含了当前区块 否则返回-1 bytes32
        blockhash(blockNum - 1); 
        // 当前区块的时间戳 uint
        block.timestamp;
        // 当前交易发送的wei值 uint
        msg.value; 

        // 扩展一些全局变量中的以太单位和时间单位
        // 1 gwei = 1e9 wei
        // 1 ether = 1e18
        assert(1 wei == 1e0);
        assert(1 wei == 1);
        assert(1 gwei == 1e9);
        assert(1 ether == 1e18);
        // solidity中的最小单位是秒
        // seconds、minutes、hours、days、weeks
        assert(1 minutes == 60 seconds); 
        assert(1 hours == 60 minutes);
        assert(1 days == 24 hours);
        assert(1 weeks == 7 days);


        return (sender, blockNum, data);
    }

    // ------------------------------------------------------------------ 数据存储 ---------------------------------
    // 引用类型: 数组 结构体. 这类变量比较复杂, 占用存储空间大 使用时必须声明存储的位置
    /*
        三类数据存储位置:
        1. storage: 合约里的状态变量默认都是storage, 存储在链上. 消耗的gas多. 
        2. memory: 函数里的参数和临时变量一般都用memory, 村存储在内存中, 不上链. 尤其返回类型时变长的情况下, 必须加memory修饰. 例如: string bytes array struct
        3. calldata: 和memory类似, 存储在内存中, 不上链. 与memory不同点在于calldata变量不能修改(immutable), 一般用于函数的参数

        不同存储类型的变量相互赋值时, 有时会产生独立的副本, 有时会产生引用, 规则如下：
        1. 合约的状态变量(storage)赋值给函数的状态变量(storage) 会创建引用, 改变新变量会影响原变量
        2. memory 赋值给 memory 会创建引用, 修改新变量会影响原变量
        3. 其他情况下都是创建副本 修改新变量不会修改原变量
    */

    function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
        //参数为calldata数组，不能被修改
        // _x[0] = 0 //这样修改会报错
        return(_x);
    }


    uint[] x = [1,2,3]; // 状态变量：数组 x
    function fStorage() public{
        //声明一个storage的变量 xStorage，指向x。修改xStorage也会影响x
        uint[] storage xStorage = x;
        xStorage[0] = 100;
    }

    function fMemory() public view {
        uint[] memory xMemory = x;
        // 这样修改不会改变原变量 
        xMemory[0] = 100;
    }
}

