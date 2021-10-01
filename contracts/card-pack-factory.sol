// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-factory.sol";

contract CardPackFactory is CardFactory {

    uint cardPackFee = 0.005 ether;
    uint cardPackQuantity = 10;
    uint rareCardOdds = 3;
    uint exoticCardOdds = 25;
    uint legendaryCardOdds = 100;

    mapping (address => uint) public ownerCardCount;
    mapping (address => bool) public existingUser;

    function purchaseCardPack() external payable {
        require(msg.value == cardPackFee, "VALUE SENT NOT EQUAL TO CARD FEE");
        _createCardPack();
    }

    function _createCardPack() internal {
        uint cardCount = 0;

        cardCount = createNonCommonCard(legendaryCardOdds, cardCount, 3);
        cardCount = createNonCommonCard(exoticCardOdds, cardCount, 2);
        cardCount = createNonCommonCard(rareCardOdds, cardCount, 1);
        createCommonCards(cardCount, cardPackQuantity);

        ownerCardCount[msg.sender] = ownerCardCount[msg.sender] + cardPackQuantity;
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