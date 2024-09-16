// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FunctionsReturn {

    // returns: 跟在函数后面, 用于声明返回类型和变量名
    // return: 用于函数主体, 返回指定变量
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        // [1,2,3] 会默认是uint8类型,所有对一个元素强转为uint256
        return(1, true, [uint256(1),2,5]);
    }


    // 在returns中同时声明类型和返回的变量名, solidity会初始化这些变量, 并返回这些变量值, 无需return
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false;
        _array = [uint256(3),2,1];
    }

    
    // 解构赋值
    function readReturn() public pure {
        uint256 _number;
        bool _bool;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        bool _bool2;
        (, _bool2, ) = returnNamed();
    }
}