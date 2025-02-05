// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";

contract TicketMarketplace is ITicketMarketplace {
    address public owner;
    uint128 public currentEventId;
    ITicketNFT public nftContract;
    address public ERC20Address;

    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }
    mapping(uint128 => Event) public events;
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }

    constructor(address _ERC20Address) {
        owner = msg.sender;
        ERC20Address = _ERC20Address;
        nftContract = new TicketNFT();
    }

    function createEvent(
        uint128 maxTickets,
        uint256 pricePerTicket,
        uint256 pricePerTicketERC20
    ) external override onlyOwner {
        events[currentEventId] = Event({
            nextTicketToSell: 0,
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20
        });
        emit EventCreated(
            currentEventId,
            maxTickets,
            pricePerTicket,
            pricePerTicketERC20
        );
        currentEventId++;
    }

    function setMaxTicketsForEvent(
        uint128 eventId,
        uint128 newMaxTickets
    ) external override onlyOwner {
        require(
            newMaxTickets >= events[eventId].maxTickets,
            "The new number of max tickets is too small!"
        );
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(
        uint128 eventId,
        uint256 price
    ) external override onlyOwner {
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(
        uint128 eventId,
        uint256 price
    ) external override onlyOwner {
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(
        uint128 eventId,
        uint128 ticketCount
    ) external payable override {
        Event storage eventInfo = events[eventId];

        uint256 totalPrice;
        unchecked {
            totalPrice = eventInfo.pricePerTicket * ticketCount;
        }
        require(
            totalPrice / ticketCount == eventInfo.pricePerTicket,
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets."
        );

        require(
            eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!"
        );
        require(
            msg.value >= totalPrice,
            "Not enough funds supplied to buy the specified number of tickets."
        );

        for (uint128 i = 0; i < ticketCount; i++) {
            nftContract.mintFromMarketPlace(
                msg.sender,
                (uint256(eventId) << 128) | (eventInfo.nextTicketToSell + i)
            );
        }
        eventInfo.nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(
        uint128 eventId,
        uint128 ticketCount
    ) external override {
        Event storage eventInfo = events[eventId];
        uint256 totalPrice;
        unchecked {
            totalPrice = eventInfo.pricePerTicketERC20 * ticketCount;
        }
        require(
            totalPrice / ticketCount == eventInfo.pricePerTicketERC20,
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets."
        );
        require(
            eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!"
        );
        IERC20 erc20 = IERC20(ERC20Address);
        require(
            erc20.balanceOf(msg.sender) >= totalPrice,
            "Not enough funds on the account."
        );
        require(
            erc20.allowance(msg.sender, address(this)) >= totalPrice,
            "Not enough allowance."
        );
        erc20.transferFrom(msg.sender, address(this), totalPrice);
        for (uint128 i = 0; i < ticketCount; i++) {
            nftContract.mintFromMarketPlace(
                msg.sender,
                (uint256(eventId) << 128) | (eventInfo.nextTicketToSell + i)
            );
        }
        eventInfo.nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(
        address newERC20Address
    ) external override onlyOwner {
        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }
}
