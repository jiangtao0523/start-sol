// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
    代理合约存储实际的链上变量   逻辑合约只需要声明这些变量，并声明逻辑函数
    当需要升级合约的逻辑的时候，只需要将代理合约指向新的逻辑合约即可
    代理合约中使用delegatecall调用逻辑合约方法的时候  实际改变的变量都是代理变量的 


    如果直接通过remix调用fallback不会有返回值是因为这属于外部调用，fallback无法显示声明返回结果，即使_delegatecall有返回值，调用方也无法获取到的
    而使用调用合约调用有返回值是因为 这是内部调用，fallback是可以获取到_delegatecall的返回值 通过解码这个返回值，返回给调用合约

    如果要升级  只需要在代理合约中新增一个函数用来改变implementation的地址函数即可

    可能存在的问题：
    1. 如果逻辑合约中的升级函数和代理合约的函数选择器存在碰撞，则可能会导致在调用对应函数的时候 caller调用的是代理函数的升级函数
        两个解决方案：
        第一个：透明代理
            普通地址不能调用代理合约中的函数，除了升级函数
        第二个：通用可升级代理
            将升级函数放到逻辑合约中去
    
*/

contract Proxy {
    address public implementation;

    address public admin;

    address public x;

    constructor(address implementation_) {
        admin = msg.sender; // 收发这个合约的用户是admin
        implementation = implementation_;
    }

    receive() external payable {
        _delegate();
    }

    fallback() external payable {
        require(msg.sender != admin);   // 透明代理 限制调用者只能调用升级函数，当代理合约和逻辑合约存在选择器碰撞的时候 也不会执行代理合约的函数
        _delegate();
    }

    // 用于逻辑合约升级
    function upgrade(address newImplementation) external {
        // 只有合约的admin 才可以升级合约
        require(msg.sender == admin);
        implementation = newImplementation;
    }

    function _delegate() internal {

        // 这里使用内联汇编是可以设置返回值  虽然这个函数本身没有返回值
        assembly {
            // 读取位置为0的地址 也就是implementation的地址
            let _implementation := sload(0)
            // 将调用参数拷贝0这个位置，偏移量也是0（偏移量都是对于返回值而言，从哪个位置开始复制） 
            calldatacopy(0, 0, calldatasize())

            // 利用deletegatecall调用implementation合约
            // 参数是 gas 目标合约地址 input的内存起始位置 input长度 output内存起始位置 output长度（output相关的给0无所谓 不会用到）
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            
            // 将返回结果拷贝到内存地址0的位置，偏移量是0（偏移量都是对于返回值而言，从哪个位置开始复制） 
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // 返回值是0就是回滚
                revert (0, returndatasize())
            }
            default {
                // 其他返回值就把数据返回
                return(0, returndatasize())
            }
        }
    }
}


contract Logic {
    // 这里的状态是为了占用的  逻辑函数中使用到的状态变量其实都是代理合约中的
    address public implementation;
    address public admin;

    uint public x = 99;

    event CallSuccess();

    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}


contract Caller {
    address public proxy;

    constructor(address proxy_) {
        proxy = proxy_;
    }

    function increment() external returns(uint) {
        // 调用proxy合约不存在的合约  会执行fallback函数
        (, bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data, (uint));
    }
}