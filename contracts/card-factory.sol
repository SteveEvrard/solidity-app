// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./player-factory.sol";

contract CardFactory is PlayerFactory {

    uint private _tokenId;
    uint private _randNonce = 0;
    Card[] public cards;

    mapping (uint => address) public cardIdToOwner;

    event CardCreated(uint cardId, uint cardType);
    
    struct Card {
        uint cardId;
        uint playerId;
        uint attributeHash;
        uint cardType;
    }

    function createCard(uint _playerId, uint _type) internal {
        uint attrHash = _generateRandomNumber();
        Card memory card = Card(_tokenId, _playerId, attrHash, _type);
        cards.push(card);
        emit CardCreated(_tokenId, _type);
        _tokenId = _tokenId + 1;
    }

    function createCustomCard(uint _playerId, uint _type, uint _attribute) internal returns(uint) {
        Card memory card = Card(_tokenId, _playerId, _attribute, _type);
        cards.push(card);
        emit CardCreated(_tokenId, _type);
        _tokenId = _tokenId + 1;
        return _tokenId;
    }

    function createNonCommonCard(uint _divisor, uint _cardCount, uint _type) internal returns(uint) {
        uint cardCount = _cardCount;

        if(_generateRandomNumber() % _divisor == 0) {
            uint playerId = _generateRandomNumber() % players.length;
            _randNonce = _randNonce + 1;
            createCard(playerId, _type);
            cardIdToOwner[_tokenId] = msg.sender;
            cardCount = _cardCount + 1;
        }

        return cardCount;
    }

    function createCommonCards(uint _cardsCreated, uint _cardPackQuantity) internal {
        for(uint i = _cardsCreated; i < _cardPackQuantity; i++) {
            uint playerId = _generateRandomNumber() % players.length;
            _randNonce = _randNonce + 1;
            createCard(playerId, 0);
            cardIdToOwner[_tokenId] = msg.sender;
        }
    }

    function _generateRandomNumber() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _randNonce)));
    }
}