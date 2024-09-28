// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 允许将ETH按权重转给一组账户中，进行分账
contract PaymentSplit {
    // 增加收益人事件
    event PayeeAdded(address account, uint256 shares);
    // 受益人提款事件
    event PaymentReleased(address to, uint256 amount);
    // 合约收款事件
    event PaymentReceived(address from, uint256 amount);

    // 总份额
    uint256 public totalShares;
    // 总支付
    uint256 public totalReleased;
    // 每个受益人的份额
    mapping(address => uint256) public shares;
    // 支付给每个受益人的金额
    mapping(address => uint256) public released;
    // 受益人数组
    address[] public payees;

    // 初始化受益人数组 和 每个受益人的份额 和 总份额  当这个合约部署的时候这些值就是确定了的，不会变更
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }       
    }

    // 收到以太币触发收款事件
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    // 受益人提款函数  所有人都可以调用 但是只有_account账户可以收到转账 
    function release(address payable _account) public virtual {
        // _account必须是受益人
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // 计算收益人能够提款的金额
        uint256 payment = releasable(_account);
        // 能够提款的金额需要 > 0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // 总提款金额新增本次提款金额
        totalReleased += payment;
        // 该收益人提款的金额新增本次提款金额
        released[_account] += payment;

        // 给受益人转账
        _account.transfer(payment);
        // 触发提款事件
        emit PaymentReleased(_account, payment);
    }

    
    // 返回账户可提款ETH
    function releasable(address _account) public view returns(uint256) {
        // 合约一共收到了多少ETH
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    // 返回账户可提款的ETH
    function pendingPayment(address _account, uint256 _totalReceived, uint256 _alreadyReleased) public view returns(uint256) {
        // _account 账户可以提款的金额 = (合约总收到的金额 * 该账户的份额) / 合约总份额 - 该账户已经提款的金额
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    // 新增收益人对应的份额  只能在构造函数调用  初始化后受益人数组不会变更
    function _addPayee(address _account, uint256 _accountShares) private {
        // 受益人地址不为0
        require(_account != address(0), "PaymentSplitter: account is the zero address");       
        // 受益人份额不为0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // 收益人不能重复
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");

        // 受益人数组添加新的收益人
        payees.push(_account);
        // 配置每个人受益人的收益份额
        shares[_account] = _accountShares;

        // 总份额是所有收益份额之和   每个收益人可以分的钱 = 每个人收益人的份额 * 账户总收到的钱 / 总份额
        totalShares += _accountShares;
        // 触发新增受益人事件
        emit PayeeAdded(_account, _accountShares);
    }
}