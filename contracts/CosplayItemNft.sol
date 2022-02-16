// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CosplayItemNft is ERC721URIStorage {    
    
    uint public _tokenIds;          

    constructor() ERC721("COSPLAYTOKEN", "COSPLAY") {
        _tokenIds = 0;
    }    

    function mint(string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds++;

        uint256 newItemId = _tokenIds;
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}