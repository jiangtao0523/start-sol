// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Event {

    mapping(address => uint256) public _balance;

    // 定义事件
    // indexd 修饰的参数会在日志的topics中
    /*
        日志包含了topics 和 data两个部分
        1. topics是一个主题数组，长度不能超过4，第一个元素是事件签名（其实就是事件的哈希）
            除了第一个元素还可以至多包含3个indexd参数，indexd修饰的参数可以用于检索事件的索引键。
            indexd参数大小固定是256bit，如果参数太大了，会自定计算哈希值存储在主题数组中
        2. 事件中不带indexd的参数会被存储在data中，data的数据不能直接被索引，但可以存储任意大小的数据。data上存储的数据消耗的gas小于topics

    */
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(address from, address to, uint256 value) external {
        _balance[from] = 10000000;

        _balance[from] -= value;
        _balance[to] += value;

        // 触发事件
        emit Transfer(from, to, value);
    }

}