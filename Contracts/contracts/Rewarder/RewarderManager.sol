//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RewarderManager{


    address internal owner;
    address dropStorage;
    address server1; //main server
    address server2; //oper server
    mapping (address => uint) public session;
    IERC1155 RobotParts;

    //ivents

    //[[[1, 2, 3, 4, 5],"0xb9ce63b2df603c417d12d9cea3a81c019b190fcc", 0,"0xcd5181715c25e45f67efc69c0c5901489dae878c021c167a689ec81213dd1cb15f8c9bd5eb784071c3e376861de2d1793145fda3250bb34f52224fc200ba36681b"], [[1, 2, 3, 4, 5],"0xb9ce63b2df603c417d12d9cea3a81c019b190fcc", 123,"0x8d81573de27efa4152b6e13a6836ad6dbe3eac2c823d571b15b1103ded8ac7e56fd1735a4986df351f5faa0abdfb6d86e9a74afee3123803e10b6a4778753bc51c"], [[1, 2, 3, 4, 5],"0xb9ce63b2df603c417d12d9cea3a81c019b190fcc", 12512,"0x8964beb84fb84f70e75e50e8f25606f1f4d3eff6468d7638fa0834456d3120e06bcbacd3bf6e1ade582bfefc31e9bf392d41a9a28daaa252433b1dfe73046a681b"]]
    //"0x8be48c31f9f51a794e8304ca67f55d66c223be9a690f8cbe8e94bcfc2f39900a76656fcd97a8a7180d5738e92aa6016f7da015e596b7a3bba701723fe0f2eb451c"
    //0xb9cE63B2Df603c417d12d9ceA3A81c019b190Fcc
    
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

    function setServer1 (address server1_) public{
        require(msg.sender == owner, "You are not an owner");
        server1 = server1_;
    }
    function setServer2 (address server2_) public{
        require(msg.sender == owner, "You are not an owner");
        server2 = server2_;
    }

    function unstorage (transaction[] memory _txs, bytes memory sign)public {
        require(areAllTxsSigned(_txs, sign), "RewarderManager: wrong signature");
        session[msg.sender] += 1;
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

    function areAllTxsSigned(transaction[] memory _txs, bytes memory sign) private view returns(bool){
        
        bytes memory gsign;
        for (uint i = 0; i < _txs.length; i++){
            gsign = abi.encodePacked(gsign, _txs[i].sign);
        }
        bool r = isSigned(keccak256(gsign), sign, server2);
        for (uint i = 0; i < _txs.length; i++){
            r = isTxSigned(_txs[i], server1) && r;
        }
        return r; 
    }

    function isTxSigned (transaction memory _tx, address _address)private view returns(bool){
        bytes32 _messageHash = keccak256(txMessage(_tx));
        return isSigned(_messageHash, _tx.sign, _address);
    }

    function txMessage(transaction memory _tx)private view returns(bytes memory){
        return abi.encodePacked(_tx.rewards[0],_tx.rewards[1],_tx.rewards[2],_tx.rewards[3],_tx.rewards[4],_tx.address_, _tx.id, msg.sender, session[msg.sender]);
    }

    function isSigned (bytes32 _messageHash, bytes memory _sign, address _address)private pure returns(bool){
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