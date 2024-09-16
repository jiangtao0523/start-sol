// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 可以定义在合约之外 可以携带参数 需要配合revert使用
error TransferNotOwner(address sender);

contract Exception {

    mapping(uint256 => address) public _owners;

    function transferOwner1(uint256 tokenId, address newOwner) public {
        address add1 = 0x0000000000000000000000000000000000000001;
        if(add1 != msg.sender) {
            revert TransferNotOwner(msg.sender);
        }

        _owners[tokenId] = newOwner;
    }


    function transferOwner2(uint256 tokenId, address newOwner) public {
        // require 是0.8版本之前的方式，目前还是有很多合约在使用。会随着描述的字符串长度的变长消耗的gas费变多
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    function transferOwner3(uint256 tokenId, address newOwner) public {
        // 一般是开发自己debug用的 不能抛出异常 
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }

    // 实际中error消耗的gas费最少 其实是assert require消耗的gas费最多
    // 生产中推荐使用error
}