// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ABIEncodeDecode {
    uint x = 10;
    address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    string name = "0xAA";
    uint[2] array = [5, 6]; 


    /*
        abi编码有4个函数
        abi.encode(): 会将每个参数填充为32字节的数据，拼接在一起 
        abi.encodePacked(): 类似于encode，但是会把encode填充的很多0省略
        abi.encodeWithSiganature(): 第一个参数是函数的签名，后面的参数才是需要编码的参数，其实就是在encode前面加上4个字节的函数选择器
        abi.encodeWithSelector(): 第一个参数 bytes4(keccak256("函数签名")), 后面的参数是需要编码的参数，结果和encodeWithSignature一样
    */
    function encode() external view returns(bytes memory result) {
        result = abi.encode(x, addr, name, array);
    }

    function encodeUint(string memory _x) external pure returns(bytes memory result) {
        result = abi.encode(_x);
    }

    function encodePackedUint(string memory _x) external pure returns(bytes memory result) {
        result = abi.encodePacked(_x);
    }

    function encodeWithSignature() public view returns(bytes memory result) {
        result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])", x, addr, name, array);
    }

    function encodeWithSelector() public view returns(bytes memory result) {
        result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")), x, addr, name, array);
    }


    // ================================================================= 解码 ===================================
    function decode(bytes memory data) public pure returns(uint _x, address _address, string memory _name, uint[2] memory _array) {
        (_x, _address, _name, _array) = abi.decode(data, (uint, address, string, uint[2]));
    }
}