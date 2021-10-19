// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CardFactory is Ownable {

    uint _tokenId;
    uint private _randNonce = 0;
    uint totalPlayers = 189;

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

    function createCard(uint _playerId, uint _type) internal {
        uint attrHash = _generateRandomNumber();
        Card memory card = Card(_tokenId, _playerId, attrHash, _type, false);
        cardIdToCard[_tokenId] = card;
        emit CardCreated(_tokenId, _type, _playerId, attrHash, msg.sender);
        cardIdToOwner[_tokenId] = msg.sender;
        userOwnedCards[msg.sender].push(_tokenId);
        cardIsAtIndex[_tokenId] = userOwnedCards[msg.sender].length - 1;
        _tokenId = _tokenId + 1;
    }

    function createCustomCard(uint _playerId, uint _type, uint _attribute) internal returns(uint) {
        Card memory card = Card(_tokenId, _playerId, _attribute, _type, false);
        cardIdToCard[_tokenId] = card;
        emit CardCreated(_tokenId, _type, _playerId, _attribute, msg.sender);
        return _tokenId;
    }

    function createNonCommonCard(uint _divisor, uint _cardCount, uint _type) internal returns(uint) {
        uint cardCount = _cardCount;

        if(_generateRandomNumber() % _divisor == 0) {
            uint playerId = _generateRandomNumber() % totalPlayers;
            _randNonce = _randNonce + 1;
            createCard(playerId, _type);
            cardCount = _cardCount + 1;
        }

        return cardCount;
    }

    function createCommonCards(uint _cardsCreated, uint _cardPackQuantity) internal {
        for(uint i = _cardsCreated; i < _cardPackQuantity; i++) {
            uint playerId = _generateRandomNumber() % totalPlayers;
            _randNonce = _randNonce + 1;
            createCard(playerId, 0);
        }
    }

    function _generateRandomNumber() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _randNonce)));
    }

    function setTotalPlayers(uint _count) external onlyOwner {
        totalPlayers = _count;
    }

    function getUserOwnedCards(address _address) external view returns(uint[] memory) {
        return userOwnedCards[_address];
    }
}