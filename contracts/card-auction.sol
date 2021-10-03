// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-ownership.sol";

contract CardAuction is CardOwnership {

    uint maxAuctionDuration = 604800;
    uint totalCardsForSale;
    mapping(uint => bool) public cardIsForSale;
    mapping(uint => uint) public cardToCurrentBid;
    mapping(uint => address) public leadingBidder;
    mapping(uint => uint) public auctionExpireDate;
    
    event AuctionOpened(uint _cardId, uint _startingBid, uint _currentTime);
    event BidPlaced(uint _cardId, uint _bid, address _bidder);

    modifier onlyCardOwner(uint _cardId) {
        address owner = cardIdToOwner[_tokenId];
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
        totalCardsForSale = totalCardsForSale + 1;
        emit AuctionOpened(_cardId, _startingBid, block.timestamp);
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

        address payable beneficiary = payable(cardIdToOwner[_cardId]);

        beneficiary.transfer(cardToCurrentBid[_cardId]);
        cardIdToOwner[_cardId] = leadingBidder[_cardId];
        cardIsForSale[_cardId] = false;
        cardToCurrentBid[_cardId] = 0;
        leadingBidder[_cardId] = address(0);
        auctionExpireDate[_cardId] = 0;
        totalCardsForSale = totalCardsForSale - 1;
    }

    function getAuctionTimeRemaining(uint _cardId) external view returns(bool) {
        return auctionExpireDate[_cardId] <= block.timestamp;
    }
}