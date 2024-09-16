// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract functions {

    /*
        函数定义形式：
        function <function_name>(<parameter types>) {external|internal|public|private} [pure|view|payable] [returns (<return types>)]
        1. [] 修饰的部分是可选的. {} 修饰的必须要写的

        2. 函数可见性修饰符, 一共有4种
            public: 内部外部均可见
            private: 只能从合约内部访问, 继承的合约也不能使用
            external: 只能从合约外部访问(但是合约内部可以通过this.function_name 调用)
            internal: 只能从合约内部访问, 继承合约可以访问

            注意：
            合约中的可见性是一定需要定义的, 没有默认值
            public|private|external|internal 也可以修饰变量, public修饰的变量会自动生成同名的getter函数, 用来查询数值. 未标明可见性状态变量, 默认是internal.

        3.决定函数功能的修饰符, 一共有3个
            payable: 带有payable的函数可以转入ETH
            pure: 既不能读取也不能写入状态变变量
            view: 能读取状态但是不能写入状态变量
            默认是既可以读取也可以访问
    */

    function add(uint x, uint y) external pure returns (uint) {
        return x + y;
    }

    function sub(uint x, uint y) external pure returns (uint) {
        return x - y;
    }
}