// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SendETH {

    constructor() payable {}

    receive() external payable {}

    function transfer(address payable _to, uint amount) external payable {
        // 使用 接收方地址.transfer发送ETH
        // gas限制2300 
        // 如果转账失败 会自动revert
        _to.transfer(amount);
    }


    error SendFail();
    function send(address payable _to, uint amount) external payable {
        // 接收方.send 发送ETH
        // gas限制是2300 
        // 转账失败 不会自动revert 需要手动处理返回值处理revert
        bool success = _to.send(amount);
        if(!success) {
            revert SendFail();
        }
    }


    error CallFail();
    function callETH(address payable _to, uint amount) external payable {
        // 调用方式：接收方.call{value: ETH数量}("")
        // 没有gas限制，可以支持对方合约fallback或receive函数实现复杂逻辑
        // 返回值是(bool, bytes) 其中bool是转账结果
        // 不会自动revert 需要根据转账结果进行手动revert
        (bool success, ) = _to.call{value: amount}("");
        if(!success) {
            revert CallFail();
        }
    }



}