// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DeleteContract {

    /*
        selfdestruct(address) 只是将合约的ETH转到指定的地址 该合约依然存在，可以被调用
    */

    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // 调用selfdestruct销毁合约，并把剩余的ETH转给msg.sender
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint balance){
        balance = address(this).balance;
    }
}