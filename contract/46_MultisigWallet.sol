// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


/*
    多签钱包：每次转账都需要有指定个数的签名才能转账成功
*/
contract MultiSigWallet {
    // 交易成功事件
    event ExecutionSuccess(bytes32 txHash);
    // 交易失败事件
    event ExecutionFailure(bytes32 txHash);
    // 多签持有人数组
    address[] public owners;
    // 记录地址是否是多签
    mapping(address => bool) public isOwner;
    // 多签持有人数量
    uint256 public ownerCount;
    // 多签执行门槛 
    uint256 public threshold;
    // 交易执行成功  nonce+1
    uint256 public nonce;

    receive() external payable {}

    constructor(address[] memory _owners, uint256 _threshold) {
        _setupOwners(_owners, _threshold);
    }

    // 初始化状态变量
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // threshold值需要 >= 1 且需要 <= 签名持有人的数量
        require(threshold == 0, "threshold has been initialized");
        require(_threshold <= _owners.length, "threshold mest less than owners count");
        require(_threshold >= 1, "multiSig need more than one sig");

        // 将每个签名持有者加入到状态变量中的签名持有者数组
        // 将每个持有者都设置为多签类型
        for(uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && owner != address(this) && !isOwner[owner],
             "owner is not zero and not this contract address and before not a singleSig");
             owners.push(owner);
             isOwner[owner] = true;
        }
        // 初始化多签持有者账户的数量
        ownerCount += _owners.length;
        // 初始化多签执行门槛
        threshold = _threshold;
    }


    // 执行交易
    // to 目标合约
    // value 交易的eth
    // data calldata
    // signatures 打包的签名  多个签名拼接
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // 计算交易的hash
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        // 交易计数值+1
        nonce++;
        // 验证交易
        checkSignatures(txHash, signatures);
        // 执行交易
        (success, ) = to.call{value: value}(data);
        if (success) {
            emit ExecutionSuccess(txHash);
        } else {
            emit ExecutionFailure(txHash);
        }
    }


    // 签名校验
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        uint256 _threshold = threshold;
        // 1个签名是65个字节  多个签名会拼接起来
        require(signatures.length >= _threshold * 65, "signatures count not enough to transaction");

        // 利用ecrecore验证签名是否有效  会返回一个地址
        // 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 利用isOwner确认地址多签地址
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for(i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // 通过这个内置的函数  可以得到一个地址
            currentOwner = ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
                ), 
                v, 
                r, 
                s
            );

            require(currentOwner > lastOwner && isOwner[currentOwner], "");
            lastOwner = currentOwner;
        }
    }


    // 多个合并的签名 拆分成一个一个的签名  每次返回每个签名对应的 r s v
    function signatureSplit(bytes memory signatures, uint256 pos) 
        internal pure returns(uint8 v, bytes32 r, bytes32 s) {
        
        assembly {
            // 计算每个签名的开始位置 
            // 当 i = 0, 0x41是65, 第一个签名的起始位置就是0; i=1 第二个签名的起始位置就是65
            let signaturePos := mul(0x41, pos)
            // mload从指定内存地址中加载32个字节
            // 针对于pos = 1  signaturePos = 65  执行完第二个add操作码后是 65+32=97
            // 再将第二个add的结果和签名的起始地址相加 就是r的起始地址
            // r s 都是32字节  v是1字节
            // v只有1个字节 但是mload会默认加载32个字节所以和0xff做与运算得到32个字节的最后1个字节
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }


    /*
        to 目标合约地址
        value 支付的以太坊
        data calldata(选择器+参数)        
        _nonce 交易的nonce
        chainId 交易的链Id
    */
    function encodeTransactionData(
        address to, 
        uint256 value, 
        bytes memory data, 
        uint256 _nonce, 
        uint256 chainid
    ) public pure returns(bytes32) {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                to, value, keccak256(data), _nonce, chainid
            )
        );

        return safeTxHash;
    }

}