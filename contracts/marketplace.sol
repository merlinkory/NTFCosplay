// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarketPlace{

    event offerCreated(uint indexed offerId, address indexed hostContract, address indexed offerer,  uint tokenId, uint price, string uri);
    event OfferClosed(uint indexed offerId, address indexed buyer);
    event BalanceWithdrawn (address indexed beneficiary, uint amount);
    


    uint public offeringNonce = 1;

    struct offering {
        address owner;
        address hostContract;
        uint tokenId;
        string uri;
        uint price;
        bool active; 
    }
    
    // mapping (bytes32 => offering) public offeringRegistry;
    offering[] public offers;
    
    mapping (address => uint) public balances;
    mapping (address => uint) public tokenBalances;

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
        uint[] memory results = new uint[](tokenBalances[_address]);
        uint counter = 0;
        for(uint i = 0; i<=offers.length; i++){
            if(offers[i].owner == _address && offers[i].active == _active){
                results[counter] = i;
                counter++;
            }
        }

        return results;
    }

    function removeFromSale(uint _offerId) external{
        // offers[_offerId].active == false;
        require(msg.sender == offers[_offerId].owner, "Only owner can delete offer");
        delete offers[_offerId];

    }

    function createOffer(address _hostContract, uint _tokenId, uint _price) external {

        ERC721 hostContract = ERC721(_hostContract);        
        address NftOwner = hostContract.ownerOf(_tokenId);

        require (msg.sender == NftOwner, "Only owner of NFT can create offerings");

        string memory uri = hostContract.tokenURI(_tokenId);

        offers.push(offering(msg.sender,_hostContract,_tokenId,uri,_price,true));

        tokenBalances[msg.sender]++;                   
        emit  offerCreated(offers.length, _hostContract, msg.sender, _tokenId, _price, uri);
    }
    
    function closeOffer(uint _offerId) external payable {
        require(msg.value >= offers[_offerId].price, "Not enough funds to buy");
        require(offers[_offerId].active != false, "Offering is closed");
        ERC721 hostContract = ERC721(offers[_offerId].hostContract);
        hostContract.safeTransferFrom(offers[_offerId].owner, msg.sender, offers[_offerId].tokenId);
        offers[_offerId].active = false;

        uint commision = msg.value * fee / 100;

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