// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// import {IERC20} from "./29_ERC20.sol";
import "./29_ERC20.sol";


contract Faucet {

    /*
        代币水龙头 每个地址可以免费获取一个代币
    */
    
    uint256 public amountAllowed = 1;
    address public tokenContract;
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed receiver, uint256 indexed amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestToken() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Is Empty!");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;

        emit SendToken(msg.sender, amountAllowed);
    }
}