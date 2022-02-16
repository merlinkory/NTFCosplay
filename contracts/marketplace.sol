// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarketPlace{

    event offerCreated(bytes32 indexed offerId, address indexed hostContract, address indexed offerer,  uint tokenId, uint price, string uri);
    event OfferClosed(bytes32 indexed offerId, address indexed buyer);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    


    uint public offeringNonce;

    struct offering {
        address offerer;
        address hostContract;
        uint tokenId;
        uint price;
        bool closed; 
    }
    
    mapping (bytes32 => offering) public offeringRegistry;
    mapping (address => uint) public balances;
    uint public companyBalance ;
    bytes32[] public offersids;

    uint public fee = 1; // 1% commision for each deal;

    address public operator;
    
    constructor(){
        operator = msg.sender;
    }

    function changeOperator(address _operator) external{
        require(msg.sender == operator, "Only current operator can change it");
        operator = _operator;

    }

    function createOffer(address _hostContract, uint _tokenId, uint _price) external {

        ERC721 hostContract = ERC721(_hostContract);        
        address NftOwner = hostContract.ownerOf(_tokenId);

        require (msg.sender == NftOwner, "Only owner of NFT can create offerings");

        bytes32 offerId = keccak256(abi.encodePacked(offeringNonce, _hostContract, _tokenId));
        offersids.push(offerId);
        offeringRegistry[offerId].offerer = msg.sender;
        offeringRegistry[offerId].hostContract = _hostContract;
        offeringRegistry[offerId].tokenId = _tokenId;
        offeringRegistry[offerId].price = _price;
        offeringNonce += 1;
        
        string memory uri = hostContract.tokenURI(_tokenId);
        emit  offerCreated(offerId, _hostContract, msg.sender, _tokenId, _price, uri);
    }
    
    function closeOffer(bytes32 _offerId) external payable {
        require(msg.value >= offeringRegistry[_offerId].price, "Not enough funds to buy");
        require(offeringRegistry[_offerId].closed != true, "Offering is closed");
        ERC721 hostContract = ERC721(offeringRegistry[_offerId].hostContract);
        hostContract.safeTransferFrom(offeringRegistry[_offerId].offerer, msg.sender, offeringRegistry[_offerId].tokenId);
        offeringRegistry[_offerId].closed = true;

        uint commision = msg.value * fee / 100;

        balances[offeringRegistry[_offerId].offerer] += (msg.value - commision);
        companyBalance += commision;
        emit OfferClosed(_offerId, msg.sender);
    } 

    function withdrawBalance() external {
        require(balances[msg.sender] > 0,"You don't have any balance to withdraw");
        uint amount = balances[msg.sender];
        payable(msg.sender).transfer(amount);
        balances[msg.sender] = 0;
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function companyWithdrawal() external {
        require(msg.sender == operator, "Only current operator can do it");
        payable(msg.sender).transfer(companyBalance);
        companyBalance = 0;
    }
}