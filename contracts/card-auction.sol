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
    uint public auctionId;
    mapping(uint => bool) public cardIsForSale;
    mapping(uint => uint) public cardToCurrentBid;
    mapping(uint => address) public leadingBidder;
    mapping(uint => uint) public auctionExpireDate;
    mapping(uint => uint) public cardToAuctionId;
    
    event AuctionOpened(uint indexed auctionId, uint indexed cardId, uint startingBid, uint expireDate, address indexed owner);
    event BidPlaced(uint indexed auctionId, uint indexed cardId, uint bid, address indexed bidder, uint expireDate);
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
        require(!cardIsForSale[_cardId], 'CARD ALREADY UP FOR AUCTION');

        cardToAuctionId[_cardId] = auctionId;
        cardIsForSale[_cardId] = true;
        cardToCurrentBid[_cardId] = _startingBid;
        auctionExpireDate[_cardId] = block.timestamp + _duration;
        emit AuctionOpened(auctionId, _cardId, _startingBid, block.timestamp + _duration, msg.sender);
        auctionId = auctionId + 1;
    }

    function placeBid(uint _cardId) external payable {
        require(cardIdToOwner[_cardId] != msg.sender, 'CAN NOT BID ON CARDS YOU OWN');
        require(cardIsForSale[_cardId], 'CARD NOT FOR SALE');
        require(msg.value > cardToCurrentBid[_cardId], 'BID LOWER THAN CURRENT BID');

        address payable outbidAddress = payable(leadingBidder[_cardId]);
        if(outbidAddress != address(0)){
            outbidAddress.transfer(cardToCurrentBid[_cardId]);
        }
        cardToCurrentBid[_cardId] = msg.value;
        leadingBidder[_cardId] = msg.sender;
        emit BidPlaced(cardToAuctionId[_cardId], _cardId, msg.value, msg.sender, auctionExpireDate[_cardId]);
    }

    function endAuction(uint _cardId) public {
        require(auctionExpireDate[_cardId] <= block.timestamp);

        if(leadingBidder[_cardId] != address(0)) {
            transferCard(_cardId);
        }
        AuctionClosed(cardToAuctionId[_cardId], _cardId, cardToCurrentBid[_cardId], leadingBidder[_cardId], leadingBidder[_cardId] != address(0));
        cardIsForSale[_cardId] = false;
        cardToCurrentBid[_cardId] = 0;
        leadingBidder[_cardId] = address(0);
        auctionExpireDate[_cardId] = 0;
        cardToAuctionId[_cardId] = 0;
    }

    function transferCard(uint _cardId) private {
        address payable beneficiary = payable(cardIdToOwner[_cardId]);

        uint cardIndex = cardIsAtIndex[_cardId];
        userOwnedCards[cardIdToOwner[_cardId]][cardIndex] = 999999999999999;

        userOwnedCards[leadingBidder[_cardId]].push(_cardId);
        cardIsAtIndex[_cardId] = userOwnedCards[leadingBidder[_cardId]].length - 1;
        cardIdToOwner[_cardId] = leadingBidder[_cardId];
        beneficiary.transfer(cardToCurrentBid[_cardId]);
    }
}