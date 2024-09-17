// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Hash {

    // keccak256(数据) 是以太坊中最常用的取哈希的算法
    function hash(uint _num, string memory _string, address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num, _string, _addr));
    }  
}