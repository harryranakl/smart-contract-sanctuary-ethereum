/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(string  memory num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (string memory){
        return number;
    }
}