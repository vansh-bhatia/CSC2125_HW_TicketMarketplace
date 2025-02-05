// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }

    constructor() ERC1155("") {
        owner = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external override onlyOwner {
        _mint(to, nftId, 1, "");
    }
}