// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PlayerFactory is Ownable {

    using SafeMath for uint256;
    uint private _playerId;

    event NewPlayer(uint playerId, string name);

    struct Player {
        string name;
        uint8 teamId;
        uint8 position;
        uint16 season;
    }

    Player[] public players;
    mapping (uint => Player) public playerIdToPlayer;

    function createPlayer(string memory _name, uint8 _teamId, uint8 _position, uint16 _season) external onlyOwner {
        Player memory player = Player(_name, _teamId, _position, _season);
        players.push(player);
        playerIdToPlayer[_playerId] = player;
        emit NewPlayer(_playerId, _name);
        _playerId.add(1);
    }
}