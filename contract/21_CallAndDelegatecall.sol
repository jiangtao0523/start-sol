// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CallAndDelegatecall {

    /*
        1. call是官方推荐的触发fallback或receive发送ETH的方法
        2. 不推荐使用call来调用另一个合约  还是推荐使用声明合约变量后调用
        3. 当我们不知道对方合约的源码或ABI时，就没法生成合约变量，这时我们可以通过call来调用对方合约的函数  
    */

    event Response(bool success, bytes data);

    function callSetX(address payable _addres, uint256 x) external payable {
        (bool success, bytes memory data) = _addres.call{value: msg.value}(abi.encodeWithSignature("setX(uint256)", x));

        emit Response(success, data);
    }

    function callGetX(address _address) external returns(uint256) {
        (bool success, bytes memory data) =_address.call(abi.encodeWithSignature("getX()"));
        emit Response(success, data);
        // decode可以对返回结果进行解码   第一个参数是返回结果  第二个是需要解码的类型
        return abi.decode(data, (uint256));
    }

    function callNonExists(address _address) external {
        // 调用一个不存在的函数  如果对方合约有fallback函数  则该函数会被调用
        (bool success, bytes memory data) = _address.call(abi.encodeWithSignature("foo(uint256)"));
        emit Response(success, data);
    }
}


contract ContractB {
    uint public num;
    address public sender;

    event Response(bool success, bytes data);

    //=========================================================delegatecall================================
    
    /*
        都是传入合约c的地址
        call的方式调用 合约c的sender是合约B的地址，合约c的num是调用传入的num
        delegatecall方式调用 合约c的sender和num都不会改变 合约b的sender是用户的地址，合约b的num是传入的num

        总结：
        1. call执行上下文会切换到目标合约中，状态改变发生在目标合约
        2. delegatecall上下文保持在调用合约中，虽然执行的目标合约的代码，但是所有状态变更都在调用合约中

    */
    function callSetVars(address _address, uint _num) external payable {
        (bool success, bytes memory data) = _address.call(abi.encodeWithSignature("setVars(uint256)", _num));
        emit Response(success, data);
    }


    function delegatecallSerVars(address _address, uint _num) external payable {
        (bool success, bytes memory data) = _address.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
        emit Response(success, data);
    }
}


contract ContractC {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}