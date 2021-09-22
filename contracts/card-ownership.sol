// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./card-pack-factory.sol";
import "./erc721.sol";
import "../utils/address-utils.sol";
import "./erc721-token-receiver.sol";

contract CardOwnership is CardPackFactory, ERC721 {

    //contract address ropsten: 0x5777097744979aD86cBaFa610d9f941987565D9d

    using AddressUtils for address;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping (uint256 => address) internal idToApproval;
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    modifier canOperate(uint256 _tokenId) {
        address owner = cardIdToOwner[_tokenId];
        require(owner == msg.sender || ownerToOperators[owner][msg.sender]);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = cardIdToOwner[_tokenId];
        require(owner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[owner][msg.sender]);
        _;
    }

    modifier isValidCard(uint _cardId) {
        require(cardIdToOwner[_cardId] != address(0), "INVALID CARD");
        _;
    }

    function balanceOf(address _owner) external override view returns(uint) {
        return ownerCardCount[_owner];
    }

    function ownerOf(uint _tokenId) external override view returns(address) {
        return cardIdToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable override canTransfer(_tokenId) isValidCard(_tokenId) {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable override canOperate(_tokenId) isValidCard(_tokenId) {
        require(msg.sender == cardIdToOwner[_tokenId], "NOT CURRENT TOKEN OWNER");
        idToApproval[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external override view isValidCard(_tokenId) returns(address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns(bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        delete idToApproval[_tokenId];
        cardIdToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private canTransfer(_tokenId) isValidCard(_tokenId) {
        require(_to != address(0), "ZERO ADDRESS");
        _transfer(_from, _to, _tokenId);
        if(_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, "CANNOT RECEIVE NFT");
        }
    }

    function mintCustomCard(address _to, uint _playerId, uint _type, uint _attributes) external onlyOwner {
        uint tokenId = createCustomCard(_playerId, _type, _attributes);
        _mint(_to, tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "ZERO ADDRESS");
        require(cardIdToOwner[_tokenId] == address(0), "CARD ALREADY EXISTS");

        cardIdToOwner[_tokenId] = _to;
        ownerCardCount[_to] = ownerCardCount[_to] + 1;
    }
    
}