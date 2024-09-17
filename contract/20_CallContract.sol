// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CallContract {

    function callSetX(address _address, uint256 x) external {
        // 方式一：调用的合约名(调用的合约地址).调用的合约函数(参数)
        OtherContract(_address).setX(x);
    }

    function callGetX(OtherContract otherContract) external view returns(uint x) {
        // 方式二：调用的合约名.函数名(参数)  其实底层依然是合约地址
        x = otherContract.getX();
    }

    function callGetX2(address _address) external view returns(uint x) {
        // 方式三：创建合约变量
        OtherContract oc = OtherContract(_address);
        x = oc.getX();
        return x;
    }

    function setXTransferETH(address _address, uint x) external payable {
        // 方式四：如果目标合约的函数是payable的，那么我们可以通过调用它来给合约转账
        OtherContract(_address).setX{value: msg.value}(x);
    }


}


contract OtherContract {
    uint256 private _x = 0; // 状态变量_x
    // 收到eth的事件，记录amount和gas
    event Log(uint amount, uint gas);
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数，并且可以往合约转ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // 如果转入ETH，则释放Log事件
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // 读取_x
    function getX() external view returns(uint x){
        x = _x;
    }

    fallback() external {
        // this.getX();
    }
}