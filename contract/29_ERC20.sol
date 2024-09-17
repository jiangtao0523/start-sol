// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {

    // value单位货币从from账户转到to账户
    event Transfer(address indexed from, address indexed to, uint256 value);

    // value单位货币从from账户授权给to账户
    event Approval(address indexed from, address indexed to, uint256 value)

    // 返回代币总供给
    function totalSupply() external view returns(uint256);

    // 返回账户所持有的代币数
    function balanceOf(address account) external view returns(uint256);

    // 从调用者转账amount数量的代币到to账户
    function transfer(address to, uint256 amount) external returns(bool);

    // 返回owner账户授权给spender授权的余额
    function allowance(address owner, address spender) external view returns(uint256);

    // 调用者授权给spender账户的amount代币数量
    function approve(address spender, uint256 amount) external returns(bool);

    // 通过授权机制 从from账户转amount数量代币给to账户，转账的部分会从调用者的allowance扣除
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
}


contract ERC20 is IERC20 {

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply;

    string public name; // 代号
    string public symbol;   // 符号

    uint8 public decimals = 18; // 小数位

    // 构造函数  用于初始化代币名称和符号
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // 代币转账逻辑
    function transfer(address recipient, uint256 amount) public override return(bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override

}