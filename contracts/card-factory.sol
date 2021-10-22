// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CardFactory is Ownable {

    uint _tokenId;
    uint private _randNonce = 0;
    uint totalPlayers = 190;
    uint rareCardOdds = 9;
    uint exoticCardOdds = 39;
    uint legendaryCardOdds = 99;

    mapping (uint => address) public cardIdToOwner;
    mapping (address => uint[]) public userOwnedCards;
    mapping (uint => uint) public cardIsAtIndex;
    mapping (uint => Card) public cardIdToCard;

    event CardCreated(uint cardId, uint cardType, uint playerId, uint attributeHash, address indexed owner);
    
    struct Card {
        uint cardId;
        uint playerId;
        uint attributeHash;
        uint cardType;
        bool inUse;
    }

    function createCard(uint _index) internal {
        uint randHash = _generateRandomNumber(_index);
        uint attrHash = randHash;
        uint playerId = randHash % totalPlayers;
        uint cardType = getCardType(randHash);
        Card memory card = Card(_tokenId, playerId, attrHash, cardType, false);
        cardIdToCard[_tokenId] = card;
        emit CardCreated(_tokenId, cardType, playerId, attrHash, msg.sender);
        cardIdToOwner[_tokenId] = msg.sender;
        userOwnedCards[msg.sender].push(_tokenId);
        cardIsAtIndex[_tokenId] = userOwnedCards[msg.sender].length - 1;
        _tokenId = _tokenId + 1;
    }

    function getCardType(uint _randInt) private view returns(uint) {
        if(_randInt % legendaryCardOdds == 0) {
            return 3;
        } else if(_randInt % exoticCardOdds == 0) {
            return 2;
        } else if(_randInt % rareCardOdds == 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function createCustomCard(uint _playerId, uint _type, uint _attribute) internal returns(uint) {
        Card memory card = Card(_tokenId, _playerId, _attribute, _type, false);
        cardIdToCard[_tokenId] = card;
        emit CardCreated(_tokenId, _type, _playerId, _attribute, msg.sender);
        return _tokenId;
    }

    function _generateRandomNumber(uint _int) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _randNonce, _int)));
    }

    function setTotalPlayers(uint _count) external onlyOwner {
        totalPlayers = _count;
    }

    function getUserOwnedCards(address _address) external view returns(uint[] memory) {
        return userOwnedCards[_address];
    }

    function setRareCardOdds(uint _newOdds) external onlyOwner {
        rareCardOdds = _newOdds;
    }

    function setExotixCardOdds(uint _newOdds) external onlyOwner {
        exoticCardOdds = _newOdds;
    }

    function setLegendaryCardOdds(uint _newOdds) external onlyOwner {
        legendaryCardOdds = _newOdds;
    }
}