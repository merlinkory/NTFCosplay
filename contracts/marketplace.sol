// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract cosplayNft is ERC721 {
    function getNftCreator(uint _tokenId) external view virtual returns(address);
}

contract MarketPlace{

    event offerCreated(uint indexed offerId, address indexed hostContract, address indexed offerer,  uint tokenId, uint price, string uri);
    event OfferClosed(uint indexed offerId, address indexed buyer);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    
    struct offering {
        address creator;
        address owner;
        address hostContract;
        uint tokenId;
        string uri;
        uint price;
        uint royaltyAmount;
        bool active; 
    }
    
    // mapping (bytes32 => offering) public offeringRegistry;
    offering[] public offers;
    
    mapping (address => uint) public balances;
    mapping (address => uint) public offerCountByAddress;
    mapping (uint =>uint) public royaltyByTokenId;

    uint public offerCount = 0; // total offers in marketplace

    uint public companyBalance ;
    

    uint public fee = 1; // 1% commision for each deal;

    address public operator;
    
    constructor(){
        operator = msg.sender;
    }

    function changeOperator(address _operator) external{
        require(msg.sender == operator, "Only current operator can change it");
        operator = _operator;

    }

    function offersByAddress(address _address, bool _active) external view returns(uint[] memory){
        uint[] memory results = new uint[](offerCountByAddress[_address]);
        uint counter = 0;
        for(uint i = 0; i<offers.length; i++){
            if(offers[i].owner == _address && offers[i].active == _active){
                results[counter] = i;
                counter++;
            }
        }

        return results;
    }

    function removeFromSale(uint _offerId) external{
        require(msg.sender == offers[_offerId].owner, "Only owner can delete offer");
        delete offers[_offerId];

    }

    function createOffer(address _hostContract, uint _tokenId, uint _price, uint _royalty) external {

        cosplayNft hostContract = cosplayNft(_hostContract);        
        address nftOwner = hostContract.ownerOf(_tokenId);
        address nftCreator = hostContract.getNftCreator(_tokenId);
        require (msg.sender == nftOwner, "Only owner of NFT can create offerings");


        //if creator making offer he can set royalty 
        if (nftOwner == nftCreator){
            royaltyByTokenId[_tokenId] = _royalty;
        }


        uint tokenRoyalty = royaltyByTokenId[_tokenId];

        //adding royalty to origin price
        uint royaltyAmount = 0;
        if (tokenRoyalty > 0){
            royaltyAmount = _price * tokenRoyalty / 100;
            _price = _price + royaltyAmount;
        }

        string memory uri = hostContract.tokenURI(_tokenId);

        offers.push(offering(nftCreator,msg.sender,_hostContract,_tokenId,uri,_price,royaltyAmount, true));

        offerCountByAddress[msg.sender]++;                   
        emit  offerCreated(offers.length, _hostContract, msg.sender, _tokenId, _price, uri);
    }
    
    function closeOffer(uint _offerId) external payable {
        require(msg.sender != offers[_offerId].owner, "Owner cant buy from himself");
        require(msg.value == offers[_offerId].price, "Not enough funds to buy");
        require(offers[_offerId].active != false, "Offering is closed");

        uint tokenId = offers[_offerId].tokenId;
      

        cosplayNft hostContract = cosplayNft(offers[_offerId].hostContract);
        hostContract.safeTransferFrom(offers[_offerId].owner, msg.sender, tokenId);
        offers[_offerId].active = false;

        //send royalty
        if(offers[_offerId].royaltyAmount > 0){
            payable (offers[_offerId].creator).transfer(offers[_offerId].royaltyAmount);
        }

        uint commision = (msg.value - offers[_offerId].royaltyAmount ) * fee / 100;

        balances[offers[_offerId].owner] += (msg.value - commision);
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