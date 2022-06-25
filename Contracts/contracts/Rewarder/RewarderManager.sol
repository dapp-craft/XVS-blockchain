//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RewarderManager{


    address internal owner;
    address dropStorage;
    address coreServer; //main server
    address questServer; //oper server
    mapping (address => uint) public nonce;
    IERC1155 RobotParts;

    struct transaction{
        uint8[5] rewards;
        address address_;
        uint id;
        bytes sign;
    }

    constructor(address robotparts){
        owner = msg.sender;
        RobotParts = IERC1155(robotparts);
    }

    function changeDropStorage (address newStorage_) public {
        require(msg.sender == owner, "RewardManager: you are not an owner");
        dropStorage = newStorage_;
    }

    function setCoreServer (address server1_) public{
        require(msg.sender == owner, "You are not an owner");
        coreServer = server1_;
    }

    function setQuestServer (address server2_) public{
        require(msg.sender == owner, "You are not an owner");
        questServer = server2_;
    }

    function getSessionId (address user) public view returns(uint){
        return nonce[user];
    }
    function unstorage (transaction[] calldata _txs, bytes calldata sign)public {
        require(areAllTxsSigned(_txs, sign), "RewarderManager: wrong signature");
        nonce[msg.sender] += 1;
        uint256[] memory robotPartsAmount = new uint[](5);
        for (uint i = 0; i < _txs.length; i++){
            for(uint k = 0; k < 5; k++){
                robotPartsAmount[k] += _txs[i].rewards[k];
            }
            if (_txs[i].address_ != address(0)){
                IERC721 NFT = IERC721(_txs[i].address_);
                NFT.safeTransferFrom(dropStorage, msg.sender, _txs[i].id, "");
            }
        }
        uint256[] memory ids = new uint256[](5);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        RobotParts.safeBatchTransferFrom(dropStorage, msg.sender, ids, robotPartsAmount, "");
    }

    function areAllTxsSigned(transaction[] calldata _txs, bytes calldata sign) private view returns(bool){
        bytes memory gsign;
        for (uint i = 0; i < _txs.length; i++){
            gsign = abi.encodePacked(gsign, _txs[i].sign);
        }
        bool r = isSigned(keccak256(gsign), sign, coreServer);
        require(r, "RewarderManager: General signature error");
        for (uint i = 0; i < _txs.length; i++){
            r = isTxSigned(_txs[i], questServer) && r;
            require(r, "RewarderManager: Tx signature error");
        }
        return r; 
    }

    function isTxSigned (transaction calldata _tx, address _address)private view returns(bool){
        bytes32 _messageHash = keccak256(txMessage(_tx));
        return isSigned(_messageHash, _tx.sign, _address);
    }

    function txMessage(transaction calldata _tx)private view returns(bytes memory){
        return abi.encodePacked(_tx.rewards[0],_tx.rewards[1],_tx.rewards[2],_tx.rewards[3],_tx.rewards[4],_tx.address_, _tx.id, msg.sender, nonce[msg.sender]);
    }

    function isSigned (bytes32 _messageHash, bytes calldata _sign, address _address)private pure returns(bool){
        return recover(getEthSignedHash(_messageHash), _sign) == _address;
    }

    function getEthSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    function recover(bytes32 _messageSignedHash, bytes memory _sign)private pure returns(address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);
        //require(uint256(v) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "RewardManager: signature error");
        return ecrecover(_messageSignedHash, v, r, s);
    }
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }


}