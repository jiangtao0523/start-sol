// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ConstantAndImmutable {

    /*
        数值变量声明可以使用constant和inmmutable string和bytes可以声明为constant但不能声明为immutable
        constant必须在声明的时候初始化 之后不能改变
        immutable可以在声明或者构造函数中初始化
    */

    uint256 constant CONSTANT_NUM = 123;
    string constant CONSTANT_STRING = "0xAA";
    bytes constant CONSTANT_BYTES = "WTF";
    address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;

    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    constructor() {
        IMMUTABLE_ADDRESS = 0x0000000000000000000000000000000000000001;
    }


}
