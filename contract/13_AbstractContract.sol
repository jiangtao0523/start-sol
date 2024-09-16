// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract AbstractContract {

    /*
        1. 抽象合约需要使用abstract
        2. 合约中必须要有一个未实现的函数  函数体为空
        3. 未实现的函数必须要用virtual修饰 让子合约实现
    */

    function insertionSort(uint[] memory a) public pure virtual returns(uint[] memory);

}


/*
    接口有如下规则；
    1. 不能包含状态变量
    2. 不能包含构造函数
    3. 不能继承除接口外的其他合约
    4. 所有函数必须是external 且不能有函数体
    5. 继承接口的非抽象合约必须实现接口定义的所有函数
*/
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
}
