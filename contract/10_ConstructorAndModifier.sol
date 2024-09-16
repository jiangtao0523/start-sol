// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ConstructorAndModifier {
    address owner;

    // 构造函数仅在部署的时候自动运行一次
    constructor(address initialOwner) {
        owner = initialOwner;
    }

    // modifier用于声明函数拥有的特性 减少冗余代码. 主要用于函数前的检查
    // 定义一个modifer
    modifier OnlyOwner {
        require(msg.sender == owner);   // 检查调用者是不是owner地址
        _;  // 是就继续执行  否则报错并revert交易
    }

    function changeOwner(address _newOwner) public OnlyOwner {
        owner = _newOwner;  // 只有owner地址才能调用这个函数  并且改变owner  这是一种最常用的控制权限的方法
    }


}