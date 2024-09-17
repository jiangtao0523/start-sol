// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns(address pairAddress) {
        // 创建新的合约 新合约的地址 = hash(创建者地址, nonce) nonce可能随着事件变化而变化 所以新创建合约地址不好预测
        Pair pair = new Pair();
        pair.initialize(tokenA, tokenB);
        pairAddress = address(pair);
        allPairs.push(pairAddress);
        getPair[tokenA][tokenB] = pairAddress;
        getPair[tokenB][tokenA] = pairAddress;
    }

    function receiveETH() external payable {

    }
}