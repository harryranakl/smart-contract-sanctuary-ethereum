/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {

    string coinName = "EPIC Coin";

    uint public myBalance = 1000;

    uint testNum = 5;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping(address => Coin) internal myCoins;

    function guessNumber(uint _guess) public pure returns(bool) {
        if(_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    function getTestNum() public view returns(uint) {
        return testNum;
    }

    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for(uint i=_startFrom; i<_myCoins.length; i++) {
            string memory coin = _myCoins[i];

            if( keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find)) ) {
                return i;
            }
        }

        return 9999;
    }

    function getKeccak256(string memory str) public pure returns (bytes32) {
        bytes32 hash =  keccak256(abi.encodePacked(str));

        return hash;
    }

    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }

}