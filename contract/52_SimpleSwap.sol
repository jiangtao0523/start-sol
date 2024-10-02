// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {

    // 代币合约
    IERC20 public token0;
    IERC20 public token1;

    // 代币储备量
    uint public reserve0;
    uint public reserve1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn, 
        address tokenIn, 
        uint amountOut, 
        address tokenOut
    );

    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    function min(uint x, uint y) internal pure returns(uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns(uint z) {
        if(y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }


    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns (uint liquidity) {
        // 从流动提提供者账户 转入 对应数量的代币1和代币2
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);

        // 交易所总流动性
        uint _totalSupply = totalSupply();
        // 总流动性为0的时候  按照 代币1数量*代币2数量求平方根
        if(_totalSupply == 0) {
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // 总流动性不为0的时候 按照代币1和代币2分别计算需要新增的流动性 = 总流动性 * 按照代币转入数量 / 交易所拥有的代币数量 
            // 取小的做为需要新增的流动性
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        // 更新交易所拥有的代币1和代币2的数量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 新增流动性
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }



    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // 当前交易所拥有的代币1和代币2的余额
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        // 当前交易所流动量
        uint _totalSupply = totalSupply();
        // 如果要减少liquidity数量的流动量，amount0和amount1分别需要转走的量
        // 代币的余额 * 减少的流动量 / 总流动量
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        // 销毁流动性提供者的liquidity的流动量
        _burn(msg.sender, liquidity);

        // 当前交易所拥有的代币1和代币2中需要减少的量都转给流动性提供者
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        // 计算交易所代币1和代币2还剩余的量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 触发Burn事件
        emit Burn(msg.sender, amount0, amount1);
    }


    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut
    ) public pure returns(uint amountOut) {
        require(amountIn > 0, "INSUFFICIENT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    
    function swap(
        uint amountIn, 
        IERC20 tokenIn,
        uint amountOutMin
    ) external returns(uint amountOut, IERC20 tokenOut) {
        // 需要限制交易的代币种类是1或者2
        require(amountIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(tokenIn == token0 || tokenIn == token1, "INVALID TOKEN");

        // 获取交易所代币1和代币2的余额
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        // 如果使用token0换token1
        if(tokenIn == token0) {
            tokenOut = token1;
            // 计算amountIn数量的token1可以换多少token2
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

            // 将调用者的amountIn数量的代币0转给交易所
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            // 将交易所amountOut 代币2数量转给调用者
            tokenOut.transfer(msg.sender, amountOut);
        } else {
            // 使用token1交换token0
            tokenOut = token0;
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // 更新交易拥有的代币1和代币2的数量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 触发swap事件
        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }

}