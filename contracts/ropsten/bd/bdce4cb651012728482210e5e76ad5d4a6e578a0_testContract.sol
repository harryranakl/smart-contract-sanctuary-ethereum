/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract testContract {

    uint256 value;

    constructor (uint256 _p) {
        value = _p;
    }

    function setP(uint256 _n) payable public {
        value = _n;
    }

    function setNP(uint256 _n) public {
        value = _n;
    }

    function get () view public returns (uint256) {
        return value;
    }
}