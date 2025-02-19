/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DropListingDapp {
    address public owner;
    
    //Define a NFT drop  object 
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;

    }

    //Create a List of some sort to hold all the object
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner , "You are not the owner");
        _;
    }

    //Get the NFT drop objects list 
    function getDrop() public view returns (Drop[] memory) {
        return drops;

    }
    //Add to the NFt drop objects List
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;

        drops.push(_drop);

        uint256 id = drops.length -1;
        users[id] = msg.sender;
    }
    //Update from the NFT drop objects list
    function updateDrop(uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "you are not the owner of this drop");
            _drop.approved = false;
            drops[_index] = _drop;
        }
    
    //Approve on NFT object to enable displaying
    function appveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;

    }
    


}