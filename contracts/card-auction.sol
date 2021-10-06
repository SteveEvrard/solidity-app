// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-ownership.sol";

contract CardAuction is CardOwnership {

    uint public maxAuctionDuration = 604800;
    mapping(uint => bool) public cardIsForSale;
    mapping(uint => uint) public cardToCurrentBid;
    mapping(uint => address) public leadingBidder;
    mapping(uint => uint) public auctionExpireDate;
    
    event AuctionOpened(uint indexed cardId, uint startingBid, uint expireDate);
    event BidPlaced(uint indexed cardId, uint bid, address bidder);
    event AuctionClosed(uint indexed cardId, uint salePrice, address to);

    modifier onlyCardOwner(uint _cardId) {
        address owner = cardIdToOwner[_cardId];
        require(owner == msg.sender, 'ONLY CARD OWNER CAN POST IT FOR AUCTION');
        _;
    }

    modifier checkAuctionDuration(uint _duration) {
        require(_duration <= maxAuctionDuration, 'BID DURATION NOT ALLOWED');
        _;
    }

    function createCardAuction(uint _cardId, uint _startingBid, uint _duration) external checkAuctionDuration(_duration) onlyCardOwner(_cardId) {
        require(!cardIsForSale[_cardId], 'CARD ALREADY UP FOR AUCTION');

        cardIsForSale[_cardId] = true;
        cardToCurrentBid[_cardId] = _startingBid;
        auctionExpireDate[_cardId] = block.timestamp + _duration;
        emit AuctionOpened(_cardId, _startingBid, block.timestamp + _duration);
    }

    function placeBid(uint _cardId) external payable {
        require(cardIdToOwner[_cardId] != msg.sender, 'CAN NOT BID ON CARDS YOU OWN');
        require(cardIsForSale[_cardId], 'CARD NOT FOR SALE');
        require(msg.value > cardToCurrentBid[_cardId], 'BID LOWER THAN CURRENT BID');

        address payable outbidAddress = payable(leadingBidder[_cardId]);
        outbidAddress.transfer(cardToCurrentBid[_cardId]);
        cardToCurrentBid[_cardId] = msg.value;
        leadingBidder[_cardId] = msg.sender;
    }

    function endAuction(uint _cardId) external {
        require(auctionExpireDate[_cardId] <= block.timestamp);

        if(leadingBidder[_cardId] != address(0)) {
            transferCard(_cardId);
        }
        cardIsForSale[_cardId] = false;
        cardToCurrentBid[_cardId] = 0;
        leadingBidder[_cardId] = address(0);
        auctionExpireDate[_cardId] = 0;
    }

    function transferCard(uint _cardId) internal {
        address payable beneficiary = payable(cardIdToOwner[_cardId]);

        beneficiary.transfer(cardToCurrentBid[_cardId]);
        cardIdToOwner[_cardId] = leadingBidder[_cardId];
    }
}