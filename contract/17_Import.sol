// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 1. 通过想对路径导入
import './09_ControlFlow.sol';

// 2. 通过全局定位符导入特定的合约
// import {ControlFlow} from './09_ControlFlow.sol';

// 3. 通过网址引用
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';

// import 语句在版本声明语句之后  其他代码之前

contract Import {
    // using Address for address;

    uint256 public a;

    ControlFlow cf = new ControlFlow();
    
    function test() external {
        a = cf.forLoopTest();
    }

}