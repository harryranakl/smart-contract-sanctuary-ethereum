/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ILove {

     string _message;

     constructor(string memory message){
         _message = message;
     }
   function ShowMessage() public view returns(string memory){
       return _message;
       
   }
 
}