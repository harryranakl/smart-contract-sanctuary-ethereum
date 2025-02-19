/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract OffenderRegistry {
  
    address private owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        //console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    // custom types
    struct defaulter {
        uint id;
        string name;
        string passportNumber;
        string passportCountry;
        string blacklistCountry;
        string offenceCategory;
        string ipfsDocumentLink;
    }

    mapping (uint => defaulter) defaulters;
    uint defaulterCounter;

    function registerNewOffender(string memory _name, 
    string memory _passportNumber, 
    string memory _passportCountry,
    string memory _blacklistCountry,
    string memory _offenceCategory,
    string memory _ipfsDocumentLink) public isOwner {

        defaulterCounter++;

        defaulters[defaulterCounter] = defaulter(
            defaulterCounter,
            _name,
            _passportNumber,
            _passportCountry,
            _blacklistCountry,
            _offenceCategory,
            _ipfsDocumentLink
        );
        //defaulter storage def = defaulters[defaulterCounter];
        //console.log("added offender:", def.name);
    }

    function getNumberOfOfferders() public view returns (uint _defaulterCounter){
        return defaulterCounter;
    }

    function getAllOffenders() public view returns (defaulter[] memory){
        defaulter[] memory _def = new defaulter[](defaulterCounter);
        uint _defCounter = 0;
        for(uint i = 1; i <=defaulterCounter; i++){
            _def[_defCounter] = defaulters[i];
            _defCounter++;
        }
        return _def;
    }

}