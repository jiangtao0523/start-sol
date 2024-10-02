// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/*
    对应使用方授权方而言，这个授权的操作是链下的，只需要在链下按照授权地址
*/
interface IERC20Permit {

    function permit(
        address owner, 
        address spender,
        uint256 value, 
        uint256 deadline, 
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns(uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    constructor(string memory name, string memory symbol) EIP712(name, "1") ERC20(name, symbol) {}

    function permit(
        address owner, 
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s   
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,   // 第一个参数是消息类型的hash，后面是才是每个参数值
                owner,  
                spender, 
                value, 
                _useNonce(owner), 
                deadline
            )
        );
        // 这个是EIP712封装的函数  只需要传一个消息的哈希
        // 完整的应该是  keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)) 
        // DOMAIN_SEPARATOR 有EIP712中的_domainSeparatorV4实现  
        // 实现逻辑：keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)))
        // 其中TYPE_HASH 是一个固定值  keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        // _hashedName和_hashVersion 可以通过EIP712构造函数传递  这里合约中是WTFPermit和1  block.chainid = 1 address(this)是当前合约地址
        bytes32 hash = _hashTypedDataV4(structHash);

        // 再用传过来的v r s 接触签名地址
        address signer = ECDSA.recover(hash, v, r, s);
        // 判断签名地址是否和owner地址一致
        require(signer == owner,  "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }


    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }


    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }

    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
}
