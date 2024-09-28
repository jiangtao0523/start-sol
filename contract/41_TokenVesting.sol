// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./29_ERC20.sol";

/*
    场景：web3初创公司会为团队成员分配代币，同时也会将代币低价抛售给风投和私募，如果他们同时将这些低成本的代币提现到交易所变现，币价会被击穿
    项目方一般会约定代币归属条款，在条款期内将代币线性释放，减缓抛压
*/
contract TokenVesting {
    // 提币事件
    event ERC20Released(address indexed token, uint256 amount);

    // 代币地址 => 释放数量的映射
    mapping(address => uint256) public erc20Released;
    // 受益者地址
    address public immutable beneficiary;
    // 归属期起始时间戳
    uint256 public immutable start;
    // 归属期
    uint256 public immutable duration;

    // 初始化受益者 起始时间戳 归属期
    constructor(address beneficiaryAddress, uint256 durationSeconds) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    // 受益人提取已释放的代币
    function release(address token) public {
        // 
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        erc20Released[token] += releasable; 
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    // 根据线性公式 计算已经释放的数量
    function vestedAmount(address token, uint256 timestamp) public view returns(uint256) {
        // 当前合约总共收到的代币数量 = 当前合约代币余额 + 已经提取的代币数量
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        if (timestamp < start) {
            // 如果当前时间戳 < 起始时间戳 则不能提币
            return 0;
        } else if (timestamp > start + duration) {
            // 如果当前时间大于起始时间戳+归属期  则可以提取全部代币
            return totalAllocation;
        } else {
            // 否则按照当前时间-开始时间占总归属期的占比 * 总可提取的代币量
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}