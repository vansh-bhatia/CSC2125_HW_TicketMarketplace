// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleCoin is ERC20 {
    constructor() ERC20("SampleCoin", "SampleCoin") {
        _mint(msg.sender, 100*10 ** decimals());
    }
}