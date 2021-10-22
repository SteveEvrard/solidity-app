// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CardAuction {
    struct Card {
        uint cardId;
        uint playerId;
        uint attributeHash;
        uint cardType;
        bool inUse;
    }

   function cardIdToCard(uint _cardId) virtual public returns(uint256, uint256, uint256, uint256, bool);
   function setCardIsInUse(uint _cardId) virtual public;
}

contract CardGame is Ownable {

    CardAuction cardAuction;
    uint public gameId;
    mapping(uint => Game) public gameIdToGame;
    mapping(uint => mapping(address => uint[])) gameIdToPlayerCards;
    mapping(uint => bool) cardIsPlayable;

    constructor(address _auctionAddress) {
        cardAuction = CardAuction(_auctionAddress);
    }

    struct Game {
        uint gameId;
        uint numberOfPlayers;
        uint numberOfCardsPerPlayer;
        uint entryFee;
        address[] players;
        bool open;
        bool active; 
        address winner;
    }

    struct Card {
        uint cardId;
        uint playerId;
        uint attributeHash;
        uint cardType;
        bool inUse;
    }

    event GameCreated(uint gameId, uint playerCount, uint cardCount, uint entryFee);
    event GameJoined(uint gameId, address indexed player);

    modifier checkPlayersInGame(uint _gameId, address _player) {
        bool playerInGame = false;
        address[] memory players = gameIdToGame[_gameId].players;
        for(uint i = 0; i < players.length; i++){
            if(players[i] == _player) {
                playerInGame = true;
            }
        }
        require(!playerInGame, "YOU HAVE ALREADY JOINED THIS GAME");
        _;
    }

    modifier checkCardAvailability(uint[] memory _cardIds, address _player) {
        bool canPlay = true;
        for(uint i = 0; i < _cardIds.length; i++) {
            (,,,,bool inUse) = cardAuction.cardIdToCard(_cardIds[i]);
            if(inUse) {
                canPlay = false;
            }
        }
        require(canPlay, "YOU HAVE ENTERED A CARD THAT IS ALREADY IN A GAME");
        _;
    }

    function createGame(uint _playerCount, uint _cardCount, uint _entryFee) external onlyOwner {
        gameIdToGame[gameId] = Game(gameId, _playerCount, _cardCount, _entryFee, new address[](_playerCount), true, true, address(0));
        emit GameCreated(gameId, _playerCount, _cardCount, _entryFee);
        gameId = gameId + 1;
    }

    function joinGame(uint _gameId, uint[] memory _cardIds) external payable checkPlayersInGame(_gameId, msg.sender) checkCardAvailability(_cardIds, msg.sender) {
        require(gameIdToGame[_gameId].entryFee == msg.value, "INVALID ENTRY FEE");

        gameIdToPlayerCards[_gameId][msg.sender] = _cardIds;
        for(uint i = 0; i < _cardIds.length; i++) {
            cardAuction.setCardIsInUse(_cardIds[i]);
        }
        gameIdToGame[_gameId].players.push(msg.sender);
        if(gameIdToGame[_gameId].players.length == gameIdToGame[_gameId].numberOfPlayers) {
            gameIdToGame[_gameId].open = false;
        }
        emit GameJoined(_gameId, msg.sender);
    }

    function closeGames(uint[] memory _gameIds) external onlyOwner {
        for(uint i = 0; i < _gameIds.length; i++) {
            gameIdToGame[_gameIds[i]].open = false;
        }
    }

    function endGames(uint[] memory _gameIds) external onlyOwner {
        for(uint i = 0; i < _gameIds.length; i++) {
            gameIdToGame[_gameIds[i]].active = false;
        }
    }

    function getPlayersByGameId(uint _gameId) external view returns(address[] memory) {
        return gameIdToGame[_gameId].players;
    }

    function getCardEntriesByPlayer(uint _gameId, address _user) external view returns(uint[] memory) {
        return gameIdToPlayerCards[_gameId][_user];
    }
}