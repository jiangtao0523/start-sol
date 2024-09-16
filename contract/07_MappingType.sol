// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MappingType { 

    /*
        映射的规则:
        1. key只能是内置的值类型 不能是自定义结构体 
        2. 映射的存储位置必须是storage 不能用于函数的参数和返回值
        3. 如果映射声明为public 会自动创建一个getter函数 可以通过key查询value
        4. 可以给定义好的映射新增元素 
    */
    mapping(uint => address) public idToAddress;
    mapping(address => address) public swapPair;

    function writeMap(uint _key, address _value) public {
        idToAddress[_key] = _value;
    }


}