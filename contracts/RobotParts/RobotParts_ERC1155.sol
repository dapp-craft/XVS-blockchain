//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RobotParts is ERC1155{

    address private owner;

    constructor() ERC1155("Metadata is not available yet"){
        owner = msg.sender;
        _mint(msg.sender, 0, 10**27, "");
        _mint(msg.sender, 1, 10**27, "");
        _mint(msg.sender, 2, 10**27, "");
        _mint(msg.sender, 3, 10**27, "");
        _mint(msg.sender, 4, 10**27, "");
    }

    function mintToken(address to, uint id, uint amount, bytes memory data) public {
        require(msg.sender == owner, "ERC1155: You are not an owner");
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) public {
        require(msg.sender == owner, "ERC1155: You are not an owner");
        _mintBatch(to, ids, amounts, data);
    }

    function setURI(string memory newuri) public {
        require(msg.sender == owner, "ERC1155: You are not an owner");
        _setURI(newuri);
    }
}