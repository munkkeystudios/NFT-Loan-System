// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


/*
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2   - owns 721 token with id 1   let's make this borrower
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4   - is owner of 721 and 20 contracts
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db   - owns 721 token with id 2

both id 1 and id 2 tokens whitelisted

0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB   - owns the vault, so will need erc 20 in their account, has 50000 erc30 transferred into their account

- Approved 5000 tokens to vault from onwer, 

*/
