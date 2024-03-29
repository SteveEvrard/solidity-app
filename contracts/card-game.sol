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
   function setCardUseStatus(uint _cardId, bool _isInUse) virtual public;
}

contract CardGame is Ownable {

    CardAuction cardAuction;
    uint public gameId;
    string private secret;
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
        uint playerCount;
        uint week;
        address[] players;
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
    event GameEnded(uint gameId, address indexed winner, uint prize);

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

    function createGame(uint _playerCount, uint _cardCount, uint _entryFee, uint _week) external onlyOwner {
        gameIdToGame[gameId] = Game(gameId, _playerCount, _cardCount, _entryFee, 0, _week, new address[](0), true, address(0));
        emit GameCreated(gameId, _playerCount, _cardCount, _entryFee);
        gameId = gameId + 1;
    }

    function joinGame(uint _gameId, uint[] memory _cardIds, string memory _secret) external payable checkPlayersInGame(_gameId, msg.sender) checkCardAvailability(_cardIds, msg.sender) {
        require(gameIdToGame[_gameId].entryFee == msg.value, "INVALID ENTRY FEE");
        require(compareSecret(_secret), "INVALID SECRET USED IN REQUEST");
        require(gameIdToGame[_gameId].playerCount < gameIdToGame[_gameId].numberOfPlayers, "GAME IS FULL");
        
        gameIdToPlayerCards[_gameId][msg.sender] = _cardIds;
        for(uint i = 0; i < _cardIds.length; i++) {
            cardAuction.setCardUseStatus(_cardIds[i], true);
        }
        gameIdToGame[_gameId].playerCount = gameIdToGame[_gameId].playerCount + 1;
        gameIdToGame[_gameId].players.push(msg.sender);
        emit GameJoined(_gameId, msg.sender);
    }

    function endGames(uint[] memory _gameIds, address[] memory _winners) external onlyOwner {
        for(uint i = 0; i < _gameIds.length; i++) {
            gameIdToGame[_gameIds[i]].active = false;
            gameIdToGame[_gameIds[i]].winner = _winners[i];
            address payable payoutAddress = payable(_winners[i]);
            address[] memory players = gameIdToGame[_gameIds[i]].players;
            for(uint j = 0; j < players.length; j++) {
                setCardsNotInUse(getCardEntriesByPlayer(_gameIds[i], players[j]));
            }
            uint payoutAmount = (gameIdToGame[_gameIds[i]].entryFee * gameIdToGame[_gameIds[i]].playerCount * 9) / 10;
            payoutAddress.transfer(payoutAmount);
            emit GameEnded(_gameIds[i], _winners[i], payoutAmount);
        }
    }

    function setCardsNotInUse(uint[] memory _cardIds) internal {
        for(uint i = 0; i < _cardIds.length; i++) {
            cardAuction.setCardUseStatus(_cardIds[i], false);
        }
    }

    function getPlayersByGameId(uint _gameId) external view returns(address[] memory) {
        return gameIdToGame[_gameId].players;
    }

    function getCardEntriesByPlayer(uint _gameId, address _user) public view returns(uint[] memory) {
        return gameIdToPlayerCards[_gameId][_user];
    }

    function compareSecret(string memory _secret) private view returns(bool) {
        return (keccak256(abi.encodePacked((_secret))) == keccak256(abi.encodePacked((secret))));
    }

    function setSecret(string memory _secret) external onlyOwner {
        secret = _secret;
    }
}