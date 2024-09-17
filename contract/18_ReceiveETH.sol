// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReceiveETH {

    event Received (address indexed sender, uint value);

    /*
        receive函数当合约收到了ETH转账时调用，一个合约最多一个receive函数
        不需要function关键字，不能有任何参数，不能有返回值，必须有 external payable
    */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    event fallbackCalled(address indexed sender, uint value);

    /*
        fallback函数会在调用合约不存在的函数时触发，可用于接收ETH，也可以用于代理合约
        不需要function关键字，必须有external，一般也会有payable修饰。
    */
    fallback() external payable {
        emit fallbackCalled(msg.sender, msg.value);
    }

    /*
        receive 和 fallback区别：
        msg.data为空，且存在receive会调用 receive函数
        msg.data不为空或者不存在receive函数 调用fallback函数
    */


    function getBalance() view external returns(uint) {
        return address(this).balance;
    }
}