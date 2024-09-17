// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Selector {

    event Log(bytes data);

    function mint(address to) external { 
        to;
        // 输出的结果就是函数选择器拼接上32位的参数
        emit Log(msg.data);
    }

    /*
        函数签名: 函数名(逗号分隔的参数类型) 上面的函数签名就是 min(address)
        selector: 上面msg.data中的前四个字节就是函数选择器
        method_id: 函数签名的keccak的前四个字节

        如果method_id和函数选择器一致 就说明这个函数需要被调用

        对于基础类型、固定长度、可变长度参数 计算method_id  在函数签名中只需要正常写类型 需要注意的是uint和int需要写成uint256和int256
        对于映射类型的参数 contract需要转为address，enum需要转为uint8，struct需要转为tuple
    */

    event SelectorEvent(bytes4 indexed selector);
    function elementaryParamSelector(uint256 param1, bool param2) external returns(bytes4 selectorWithElementaryParam){
        param1;
        param2;
        emit SelectorEvent(this.elementaryParamSelector.selector);
        return bytes4(keccak256("elementaryParamSelector(uint256,bool)"));
    }

    function callWithsignature() external {
        // 调用函数
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0x3ec37834, 1, 0));
        data;
        require(success, "call fail");
    }

}