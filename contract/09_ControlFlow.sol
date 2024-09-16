// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ControlFlow {

    // if else 
    function ifElseTest(uint256 _number) public pure returns(bool) {
        if(_number == 0) {
            return (true);
        } else if (_number == 1) {
            return (true);
        } else {
            return (false);
        }
    }


    // for循环
    function forLoopTest() public pure returns(uint256) {
        uint sum = 0;
        for(uint i = 0; i < 10; i++) {
            sum += i;
        }
        return (sum);
    }

    // while循环
    function whileTest() public pure returns(uint256) {
        uint sum = 0;
        uint i = 0;
        while (i < 10) {
            sum += i;
            i++;
        }
        return (sum);
    }


    // do-while循环
    function doWhileTest() public pure returns(uint256) {
        uint sum = 0;
        uint i = 0;
        do {
            sum += i;
            i++;
        } while (i < 10);

        return (sum);
    }

}