// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./29_ERC20.sol";

/*
    场景：受益人在锁仓一段时间后才能取出代币。
    代币在交易所上市，需要向交易所提供资金池，供其他用户能够买卖。代币需要质押相应的币对到资金池，做为补偿，交易所会给项目铸造相应的流动性提供者LP代币凭证
    证明他们质押了相应的份额，可以收取一定的交易手续费
*/
contract TokenLocker {
    // 代币时间锁开始事件
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    // 代币提现事件
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);

    // 被锁仓的代币合约
    IERC20 public immutable token;
    // 受益人地址
    address public immutable beneficiary;
    // 锁仓时间
    uint256 public immutable lockTime;
    // 锁仓开始时间
    uint256 public immutable startTime;

    constructor(IERC20 token_, address beneficiary_, uint256 lockTime_) {
        require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
        token = token_;
        beneficiary = beneficiary_;
        lockTime = lockTime_;
        startTime = block.timestamp;

        emit TokenLockStart(beneficiary_, address(token_), block.timestamp, lockTime_);
    }


    function release() public {
        require(block.timestamp >= startTime+lockTime, "TokenLock: current time is before release time");
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");
        token.transfer(beneficiary, amount);
        emit Release(msg.sender, address(token), block.timestamp, amount);
    }

}