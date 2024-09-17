// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract TryCatch {

    /*
        try catch只能被用于external函数和创建合约时的constructor函数
        try contractA.f() returns() {

        } catch {
            
        }

    */

    // 成功event
    event SuccessEvent();

    // 失败event
    event CatchEvent(string message);
    event CatchByte(bytes data);

    // OnlyEven even;
    // constructor() {
    //     even = new OnlyEven(2);
    // }

    function executeNew(uint a) external returns(bool success) {
        try new OnlyEven(a) returns(OnlyEven _even) {
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory message) {
            emit CatchEvent(message);
        } catch (bytes memory reason) {
            emit CatchByte(reason);
        }
    }

    // function execute(uint amount) external returns(bool success) {
    //     try even.onlyEven(amount) returns(bool _success) {
    //         emit SuccessEvent();
    //         return _success;
    //     } catch Error(string memory reason) {
    //         emit CatchEvent(reason);
    //     }
    // }

}


contract OnlyEven{
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns(bool success){
        // 输入奇数时revert
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}