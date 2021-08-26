// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./player-factory.sol";

contract CardFactory is PlayerFactory {

    using SafeMath for uint256;
    uint private _tokenId;
    uint private _randNonce = 0;
    Card[] public cards;

    mapping (uint => address) public cardIdToOwner;

    enum Type { COMMON, RARE, EXOTIC, LEGENDARY }

    event CardCreated(uint cardId, Type cardType);
    
    struct Card {
        uint cardId;
        uint playerId;
        uint attributeHash;
        Type cardType;
    }

    function createCard(uint _playerId, Type _type) internal {
        uint attrHash = _generateRandomNumber();
        Card memory card = Card(_tokenId, _playerId, attrHash, _type);
        cards.push(card);
        emit CardCreated(_tokenId, _type);
        _tokenId.add(1);
    }

    function createCustomCard(uint _playerId, Type _type, uint _attribute) internal returns(uint) {
        Card memory card = Card(_tokenId, _playerId, _attribute, _type);
        cards.push(card);
        emit CardCreated(_tokenId, _type);
        return _tokenId.add(1);
    }

    function createNonCommonCard(uint _divisor, uint _cardCount, Type _type) internal returns(uint) {
        uint cardCount = _cardCount;

        if(_generateRandomNumber() % _divisor == 0) {
            uint playerId = _generateRandomNumber() % players.length;
            createCard(playerId, _type);
            cardIdToOwner[_tokenId] = msg.sender;
            cardCount = _cardCount.add(1);
        }

        return cardCount;
    }

    function createCommonCards(uint _cardsCreated, uint _cardPackQuantity) internal {
        for(uint i = _cardsCreated; i < _cardPackQuantity; i++) {
            uint playerId = _generateRandomNumber() % players.length;
            createCard(playerId, Type.COMMON);
            cardIdToOwner[_tokenId] = msg.sender;
        }
    }

    function _generateRandomNumber() internal view returns (uint) {
        _randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _randNonce)));
    }
}