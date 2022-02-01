// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CosplayItemNft is ERC721URIStorage {
    
    
    uint public _tokenIds;
    
    
    /**
     *  коллекция под свойстава
     */
    

    constructor() ERC721("COSPLEYTOKEN", "COSPLEY") {
        _tokenIds = 0;
    }
    

    function awardItem(address player, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds++;

        uint256 newItemId = _tokenIds;
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}