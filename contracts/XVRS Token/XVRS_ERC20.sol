//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XVRS is ERC20{
    constructor() ERC20("Crossverse", "XVRS") {
        _mint(msg.sender, 3*10**26);
    }
}