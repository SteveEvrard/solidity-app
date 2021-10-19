// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-ownership.sol";

// abstract contract Aion {
//     uint256 public serviceFee;
//     function ScheduleCall(uint256 blocknumber, address to, uint256 value, uint256 gaslimit, uint256 gasprice, bytes memory data, bool schedType) virtual public payable returns (uint,address);
//     function cancellScheduledTx(uint256 blocknumber, address from, address to, uint256 value, uint256 gaslimit, uint256 gasprice, uint256 fee, bytes memory data, uint256 aionId, bool schedType) virtual public payable returns(bool);
// }

contract CardAuction is CardOwnership {

    // Aion aion;
    uint public maxAuctionDuration = 604800;
    uint public auctionId = 1;
    mapping(uint => bool) public cardIsForSale;
    mapping(uint => uint) public cardToAuctionId;
    mapping(uint => Auction) public auctionIdToAuction;

    struct Auction {
        uint auctionId;
        uint currentBid;
        address leadingBidder;
        uint expireDate;
        uint cardId;
        uint bidCount;
    }
    
    event AuctionOpened(uint indexed auctionId, uint indexed cardId, uint startingBid, uint expireDate, address indexed owner);
    event BidPlaced(uint indexed auctionId, uint indexed cardId, uint bid, address indexed bidder);
    event AuctionClosed(uint indexed auctionId, uint indexed cardId, uint salePrice, address indexed to, bool completed);

    modifier onlyCardOwner(uint _cardId) {
        address owner = cardIdToOwner[_cardId];
        require(owner == msg.sender, 'ONLY CARD OWNER CAN POST IT FOR AUCTION');
        _;
    }

    modifier checkAuctionDuration(uint _duration) {
        require(_duration <= maxAuctionDuration, 'BID DURATION NOT ALLOWED');
        _;
    }

    // Keeping for possible scheduler integration
    //
    // function createCardAuction(uint _cardId, uint _startingBid, uint _duration) external checkAuctionDuration(_duration) onlyCardOwner(_cardId) {
    //     require(!cardIsForSale[_cardId], 'CARD ALREADY UP FOR AUCTION');
    //     aion = Aion(0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256('endAuction(uint)')), _cardId);
    //     uint callCost = 500000*1e9 + aion.serviceFee();
    //     aion.ScheduleCall{value: callCost}(block.timestamp + _duration, address(this), 0, 500000, 1e9, data, true);        

    //     cardIsForSale[_cardId] = true;
    //     cardToCurrentBid[_cardId] = _startingBid;
    //     auctionExpireDate[_cardId] = block.timestamp + _duration;
    //     // emit AuctionOpened(_cardId, _startingBid, block.timestamp + _duration);
    //     AuctionOpened(auctionId, _cardId, _startingBid, block.timestamp + _duration, msg.sender);
    // }

    function createCardAuction(uint _cardId, uint _startingBid, uint _duration) external checkAuctionDuration(_duration) onlyCardOwner(_cardId) {
        require(!cardIsForSale[_cardId], 'CARD IS CURRENTLY UP FOR AUCTION');
        require(!cardIdToCard[_cardId].inUse, "CARD IS CURRENTLY IN USE");

        Auction memory auction = Auction(auctionId, _startingBid, address(0), block.timestamp + _duration, _cardId, 0);
        auctionIdToAuction[auctionId] = auction;

        cardIdToCard[_cardId].inUse = true;
        cardToAuctionId[_cardId] = auctionId;
        cardIsForSale[_cardId] = true;
        emit AuctionOpened(auctionId, _cardId, _startingBid, block.timestamp + _duration, msg.sender);
        auctionId = auctionId + 1;
    }

    function placeBid(uint _cardId) external payable {
        Auction memory auction = auctionIdToAuction[cardToAuctionId[_cardId]];
        require(cardIdToOwner[_cardId] != msg.sender, 'CAN NOT BID ON CARDS YOU OWN');
        require(cardIsForSale[_cardId], 'CARD NOT FOR SALE');
        require(msg.value > auction.currentBid, 'BID LOWER THAN CURRENT BID');

        address payable outbidAddress = payable(auction.leadingBidder);

        if(outbidAddress != address(0)){
            outbidAddress.transfer(auction.currentBid);
        }

        auctionIdToAuction[auction.auctionId].leadingBidder = msg.sender;
        auctionIdToAuction[auction.auctionId].currentBid = msg.value;
        auctionIdToAuction[auction.auctionId].bidCount = auctionIdToAuction[auction.auctionId].bidCount + 1;

        emit BidPlaced(auction.auctionId, auction.cardId, msg.value, msg.sender);
    }

    function endAuction(uint _cardId) public onlyCardOwner(_cardId) {
        Auction memory auction = auctionIdToAuction[cardToAuctionId[_cardId]];
        require(auction.expireDate <= block.timestamp, "AUCTION NOT YET FINISHED");

        if(auction.leadingBidder != address(0)) {
            transferCard(_cardId, auction.leadingBidder, auction.currentBid);
        }

        AuctionClosed(auction.auctionId, auction.cardId, auction.currentBid, auction.leadingBidder, auction.leadingBidder != address(0));
        cardIsForSale[_cardId] = false;
        cardIdToCard[_cardId].inUse = false;
        cardToAuctionId[_cardId] = 0;
    }

    function cancelAuction(uint _cardId) public onlyCardOwner(_cardId) {
        Auction memory auction = auctionIdToAuction[cardToAuctionId[_cardId]];
        require(auction.leadingBidder == address(0), "CANNOT CANCEL AN AUCTION THAT HAS BIDS");
        require(auction.expireDate > block.timestamp, "CANNOT CANCEL AN AUCTION AFTER IT IS EXPIRED");

        cardIsForSale[_cardId] = false;
        cardToAuctionId[_cardId] = 0;
    }

    function transferCard(uint _cardId, address _winner, uint _price) private {
        address payable beneficiary = payable(cardIdToOwner[_cardId]);

        uint cardIndex = cardIsAtIndex[_cardId];
        userOwnedCards[cardIdToOwner[_cardId]][cardIndex] = 999999999999999;

        userOwnedCards[_winner].push(_cardId);
        cardIsAtIndex[_cardId] = userOwnedCards[_winner].length - 1;
        cardIdToOwner[_cardId] = _winner;
        beneficiary.transfer(_price);
    }
}