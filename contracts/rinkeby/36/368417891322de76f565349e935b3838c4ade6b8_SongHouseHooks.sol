/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
Expandable ERC1155 allows contract owner to issue new tokens, each with their own max supply, mint price, and max per Address.
function "releaseNewEdition" will create a new token based on the input params, 
while function "updateExistingEdition" can change those params including increasing max supply.
function "mint" 
*/

import "./ERC1155.sol";
import "./Strings.sol";
import "./Shareholders.sol";

contract SongHouseHooks is ERC1155, Shareholders {
    using Strings for uint256;
    uint256 public currentEdition;
    uint256 public totalSupply;
    uint256 public price = 0.0001 ether;
    string public baseURI;
    string public name;
    string public symbol;
    mapping(uint256 => uint256) public totalSupplyOfToken;
    mapping(uint256 => uint256) public maxSupplyOfToken;
    
    mapping(uint256 => bool) public tokenExists;
    mapping(uint256 => bool) public salePaused;
    event SetBaseURI(string indexed _baseURI);

    constructor() ERC1155(baseURI) {
        baseURI = "";
        name = "Song House Viral Hooks";
        symbol = "SHVH";
    }

    function releaseNewEdition(uint256 _maxSupply) external onlyOwner {
        currentEdition += 1;
        tokenExists[currentEdition] = true;
        maxSupplyOfToken[currentEdition] = _maxSupply;
        salePaused[currentEdition] = true;
    }

    function releaseMultipleNewEditions(uint256[] memory _maxSupplies) external onlyOwner {
        for (uint i = 0; i < _maxSupplies.length; i++) {
            currentEdition += 1;
            tokenExists[currentEdition] = true;
            maxSupplyOfToken[currentEdition] = _maxSupplies[i];
            salePaused[currentEdition] = true;
        }
    }

    function updateExistingEdition(uint256 _edition, uint256 _maxSupply) external onlyOwner {
        require(tokenExists[_edition] == true, "This token doesnt exist.");
        maxSupplyOfToken[_edition] = _maxSupply;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function togglePause(uint256 _edition, bool _state) external onlyOwner {
        salePaused[_edition] = _state;
    }

    function mintOneOfMultiple(uint256[] memory _editions) external payable {
        uint txCost;
        uint lngth = _editions.length;
        uint256[] memory quantities = new uint256[](lngth);
        for (uint i = 0; i < _editions.length; i++) {
            require(tokenExists[_editions[i]] == true, "This token doesnt exist.");
            require(1 + totalSupplyOfToken[_editions[i]] <= maxSupplyOfToken[_editions[i]], "Not enough tokens left to mint that many.");
            totalSupplyOfToken[_editions[i]] += 1;
            totalSupply += 1;
            txCost += price;
            quantities[i] = 1;
        }
        require(msg.value == txCost, "Insufficient funds.");
        _mintBatch(msg.sender, _editions, quantities, "");
    }
    

    function mintOne(uint256 _edition, uint256 _quantity) external payable {
        require(_quantity == 1, "Only one at a time.");
        require(tokenExists[_edition] == true, "This token doesnt exist.");
        require(1 + totalSupplyOfToken[_edition] <= maxSupplyOfToken[_edition], "Not enough tokens left to mint that many.");
        require(msg.value == price, "Insufficient funds.");
        totalSupplyOfToken[_edition] += 1;
        totalSupply += 1;
        _mint(msg.sender, _edition, _quantity, "");

    }


    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 _tierID)
        public
        view
        override             
        returns (string memory)
    {
        
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tierID.toString(),".json"))
                : baseURI;
    }
}