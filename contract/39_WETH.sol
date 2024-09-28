// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    WETH是对ETH的包装 兑换比例是1:1 
    以太币本身并不符合ERC20的标准，为了提高区块链之间的互操作性，将ETH包装成符合ERC20标准的WETH

*/

contract WETH is ERC20 {

    // 存款事件
    event Deposit(address indexed dst, uint wad);

    // 取款事件
    event Withdraw(address indexed src, uint wad);

    constructor() ERC20("WETH", "WETH") {}

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    // 提取多少WETH就销毁多少WETH, 同时将合约的ETH转入提取账户
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // 存入多少ETH就铸造等值的WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

}