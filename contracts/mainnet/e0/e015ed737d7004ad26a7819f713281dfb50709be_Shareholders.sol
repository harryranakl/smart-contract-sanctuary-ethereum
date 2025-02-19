// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";

/*
Automatically distributes royalties once autoWithdrawLimit exceeded.
Developed by Co-Labs. www.co-labs.studio
*/
contract Shareholders is Ownable {
    address payable[] public shareholders;
    uint256[] public shares;
    uint256 public autoWithdrawLimit = 1 ether;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (address(this).balance > autoWithdrawLimit) {
            withdraw();
        }
    }

    constructor() { 
        shareholders.push(payable(0xDB6FfD47E81deb48360C4f73d169Fbb743Be0E26)); 
        shares.push(250);
        shareholders.push(payable(0x376776aA01c0B4f714A2B36F7258E79DA0307188)); 
        shares.push(250);
        shareholders.push(payable(0x37fb006F219781b42D50bd1efDb3C3449E3FEB1A)); 
        shares.push(250);
        shareholders.push(payable(0xb15FE66373908b9c1702fdAfC921F37B6CFf66f7));
        shares.push(83);
        shareholders.push(payable(0x95B85D3DA72b26A5847d78438f84f36322D16ef6)); 
        shares.push(83);
        shareholders.push(payable(0x25E1c3272f2268AFC42e9896Aa3eC96cD6ef4826)); 
        shares.push(84);
        

    }

    function changeShareholders(address payable[] memory newShareholders, uint256[] memory newShares) public onlyOwner {
        delete shareholders;
        delete shares;
        uint256 length = newShareholders.length;
        require(newShareholders.length == newShares.length, "number of new shareholders must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            shareholders.push(newShareholders[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = shareholders.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
        }
        return totalShares;
    }

    function changeAutoWithdrawLimit(uint256 _newLimit) external onlyOwner {
        autoWithdrawLimit = _newLimit;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = shareholders.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = shareholders[j];
            share = shares[j];
            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

   

}