// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract PublicKeyManager {

    function getPublicKey(address _address) public pure returns (bytes memory) {
        bytes memory publicKey = abi.encodePacked(_address);
        return publicKey;
    }
}