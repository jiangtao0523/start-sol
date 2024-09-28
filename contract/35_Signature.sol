// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./32_ERC721.sol";

library ECDSA {

    /*
        1. 签名者利用私钥对消息创建签名
        2. 其他人使用消息和签名恢复签名者的公钥 
    */

    function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns(bool) {
        return recoverSigner(_msgHash, _signature) == _signer;
    }

    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns(address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            /*
            前32 bytes存储签名的长度 (动态数组存储规则)
            add(sig, 32) = sig的指针 + 32
            等效为略过signature的前32 bytes
            mload(p) 载入从内存地址p起始的接下来32 bytes数据
            */
            // 读取长度数据后的32 bytes
            r := mload(add(_signature, 0x20))
            // 读取之后的32 bytes
            s := mload(add(_signature, 0x40))
            // 读取最后一个byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        return ecrecover(_msgHash, v, r, s);
    }


    // 参数是消息的hash
    // 添加 \x19Ethereum Signed Message:\n32 前缀，防止是可执行消息
    // 返回一个以太坊签名消息
    function toEthSignedMessageHash(bytes32 hash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


contract SignatureNFT is ERC721 {

    address immutable public signer; // 签名地址

    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数，初始化NFT合集的名称、代号、签名地址
    constructor(string memory _name, string memory _symbol, address _signer) ERC721(_name, _symbol) {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // 将_account和_tokenId打包消息
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash); // 计算以太坊签名消息
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSA检验通过
        require(!mintedAddress[_account], "Already minted!"); // 地址没有mint过
                
        mintedAddress[_account] = true; // 记录mint过的地址
        _mint(_account, _tokenId); // mint
    }


    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

        // ECDSA验证，调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        return ECDSA.verify(_msgHash, _signature, signer);
    }


    receive() external payable {

    }
}



contract VerifySignature {

    function getMessageHash(address _addr, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

     function verify(address _signer, address _addr, uint _tokenId, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_addr, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        // 检查签名长度，65是标准r,s,v签名的长度
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 0x20))
            // second 32 bytes
            s := mload(add(sig, 0x40))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 0x60)))
        }
    }

}