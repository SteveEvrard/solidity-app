// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-factory.sol";

contract CardPackFactory is CardFactory {

    uint cardPackFee = 0.005 ether;
    uint cardPackQuantity = 10;

    mapping (address => uint) public ownerCardCount;
    mapping (address => bool) public existingUser;

    event CardPackPurchased(address indexed owner);

    function purchaseCardPack() external payable {
        require(msg.value == cardPackFee, "VALUE SENT NOT EQUAL TO CARD FEE");
        _createCardPack();
        emit CardPackPurchased(msg.sender);
    }

    function _createCardPack() internal {
        for(uint i = 0; i < cardPackQuantity; i++) {
            createCard(i);
        }
        ownerCardCount[msg.sender] = ownerCardCount[msg.sender] + cardPackQuantity;
    }

    function setCardPackQuantity(uint _quantity) external onlyOwner {
        cardPackQuantity = _quantity;
    }

    function setCardPackFee(uint _fee) external onlyOwner {
        cardPackFee = _fee;
    }
}