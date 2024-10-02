// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// 金库合约允许把基础资产质押到合约中 换取一定的收益
interface IERC4626 is IERC20, IERC20Metadata {

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender, 
        address indexed receiver, 
        address indexed owner, 
        uint256 assets, 
        uint256 shares
    );

    // 返回金库基础资产的地址
    function asset() external view returns(address assetTokenAddress);

    // 用户向金库存入assets单位的基础资产，合约会铸造shares单位的金库额度给receiver
    function deposit(uint256 assets, address receiver) external returns(uint256 shares);

    // 需要给receiver铸造shares数量的金库资产 需要耗费assets数量的基础资产
    function mint(uint256 shares, address receiver) external returns(uint256 assets);

    // owner地址销毁asset数量的基础资产对应的金库资产 然后将assets数量基础资产转给receiver
    function withdraw(uint256 assets, address receiver, address owner) external returns(uint256 shares);

    // owner地址销毁shares数量的金库资产 将对应的基础资产给receviver地址
    function redeem(uint256 shares, address receiver, address owner) external returns(uint256 assets);

    // 合约中总基础代理资产
    function totalAssets() external view returns(uint256 totalManagedAssets);

    // assets数量的基础资产 可以换取的金库资产
    function convertToShares(uint256 assets) external view returns(uint256 shares);

    // shares数量的金库资产可以换取的基础资产
    function convertToAssets(uint256 shares) external view returns(uint256 assets);

    // 预览 存入assets数量的基础资产可以获取到多少金库资产量
    function previewDeposit(uint256 assets) external view returns(uint256 shares);

    // 预览 铸造shares数量的 金库资产可以 需要存入的基础资产量
    function previewMint(uint256 shares) external view returns(uint256 assets);
    
    // 预览 提取asset数量的基础资产需要销毁金库资产量
    function  previewWithdraw(uint256 assets) external view returns(uint256 shares);

    // 预览 销毁shares数量金额额度可以赎回的基础资产量
    function previewRedeem(uint256 shares) external view returns(uint256 assets);

    // 给receiver可铸造的最大基础资产额度
    function maxDeposit(address receiver) external view returns(uint256 maxAssets);

    // 给receiver可铸造的最大金库额度
    function maxMint(address receiver) external view returns(uint256 maxShares);

    // 地址可提取的最大基础资产额度
    function maxWithdraw(address owner) external view returns(uint256 maxAssets);

    // 地址可提取的最大金库额度
    function maxRedeem(address owner) external view returns(uint256 maxShares);  
}



contract ERC4626 is ERC20, IERC4626 {
    ERC20 private immutable _asset;
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    function asset() public view virtual override returns(address) {
        return address(_asset);
    }

    // 估计IERC20Metadata, ERC20 都有这个方法，这是都重写的意思
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns(uint8) {
        return _decimals;
    }


    // 用户向金库存入assets单位的基础资产，合约会铸造shares单位的金库额度给receiver
    function deposit(uint256 assets, address receiver) public virtual returns(uint256 shares) {
        // 计算存入assets数量的基础资产将获得金库资产量
        shares = previewDeposit(assets);
        // 先transfer 后 mint 防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // 释放存款事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // 需要给receiver铸造shares数量的金库资产 需要耗费assets数量的基础资产
    function mint(uint256 shares, address receiver) public virtual returns(uint256 assets) {
        // 要存入shares数量的金库资产需要assets数量基础资产
        assets = previewMint(shares);
        // 先transfer 后 mint 防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // 释放存款事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    // owner地址销毁asset数量的基础资产对应的金库资产 然后将assets数量基础资产转给receiver
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns(uint256 shares) {
        // 要提取assets数量的基础资产  需要burn掉的金库资产
        shares = previewWithdraw(assets);
        // 如果sender不是owner 需要给sender授权shares数量的额度
        if(msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // burn掉owner 账户的shares数量的金库资产
        _burn(owner, shares);
        // 将金库基础资产转给 receiver账户
        _asset.transfer(receiver, assets);

        // 触发取款事件
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    // owner地址销毁shares数量的金库资产 将对应的基础资产给receviver地址
    function redeem(uint256 shares, address receiver, address owner) public virtual returns(uint256 assets) {
        // 计算shares数量的金库资产对应的基础资产
        assets = previewRedeem(shares);
        if(msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    // 合约中总基础代理资产
    // totalAssets == totalSupply
    function totalAssets() public view virtual returns(uint256 totalManagedAssets) {
        // 当前合约账户的基础资产量
        return _asset.balanceOf(address(this));
    }

    // assets数量的基础资产 可以换取的金库资产
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // supply 和 totalAssets()  一直是一致的
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

    // shares数量的金库资产可以换取的基础资产
    function convertToAssets(uint256 shares) public view virtual returns(uint256 assets) {
        uint256  supply = totalSupply();
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    // 预览 存入assets数量的基础资产可以获取到多少金库资产量
    function previewDeposit(uint256 assets) public view virtual returns(uint256 shares) {
        return convertToShares(assets);
    }

    // 预览 铸造shares数量的 金库资产可以 需要存入的基础资产量
    function previewMint(uint256 shares) public view virtual returns(uint256 assets) {
        return convertToAssets(shares);
    }
    
    // 预览 提取asset数量的基础资产需要销毁金库资产量
    function  previewWithdraw(uint256 assets) public view virtual returns(uint256 shares) {
        return convertToShares(assets);
    }

    // 预览 销毁shares数量金额额度可以赎回的基础资产量
    function previewRedeem(uint256 shares) public view virtual returns(uint256 assets) {
        return convertToAssets(shares);
    }

    // 给receiver可铸造的最大基础资产额度
    function maxDeposit(address receiver) public view virtual returns(uint256 maxAssets) {
        receiver;
        return type(uint256).max;
    }

    // 给receiver可铸造的最大金库额度
    function maxMint(address receiver) public view virtual returns(uint256 maxShares) {
        receiver;
        return type(uint256).max;
    }

    // 地址可提取的最大基础资产额度
    function maxWithdraw(address owner) public view virtual returns(uint256 maxAssets) {
        return convertToAssets(balanceOf(owner));
    }

    // 地址可提取的最大金库额度
    function maxRedeem(address owner) public view virtual returns(uint256 maxShares) {
        return balanceOf(owner);
    }
}