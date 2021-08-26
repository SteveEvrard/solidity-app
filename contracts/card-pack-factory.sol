// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-factory.sol";

contract CardPackFactory is CardFactory {

    using SafeMath for uint256;
    uint cardPackFee = 0.015 ether;
    uint cardPackQuantity = 10;
    uint rareCardOdds = 10;
    uint exoticCardOdds = 100;
    uint legendaryCardOdds = 1000;

    mapping (address => uint) public ownerCardCount;
    mapping (address => bool) public existingUser;

    function purchaseCardPack() external payable {
        require(msg.value == cardPackFee);
        _createCardPack();
    }

    function _createCardPack() internal {
        uint cardCount = 0;

        cardCount = createNonCommonCard(legendaryCardOdds, cardCount, Type.LEGENDARY);
        cardCount = createNonCommonCard(exoticCardOdds, cardCount, Type.EXOTIC);
        cardCount = createNonCommonCard(rareCardOdds, cardCount, Type.RARE);
        createCommonCards(cardCount, cardPackQuantity);

        ownerCardCount[msg.sender].add(cardPackQuantity);
    }

    function setCardPackQuantity(uint _quantity) external onlyOwner {
        cardPackQuantity = _quantity;
    }

    function setCardPackFee(uint _fee) external onlyOwner {
        cardPackFee = _fee;
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