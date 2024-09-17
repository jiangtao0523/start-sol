// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FunctionOverloading {

    // 函数重载: 方法名一样但是参数不一样

    function saySomething() public pure returns(string memory){
        return("Nothing");
    }

    function saySomething(string memory something) public pure returns(string memory){
        return(something);
    }


    function f(uint8 _in) public pure returns (uint8 out) {
        out = _in;
    }

    function f(uint256 _in) public pure returns (uint256 out) {
        out = _in;
    }

    // 如果调用f(50)这里会报错  因为8既可以转成uint8 也可以转成uint256
}