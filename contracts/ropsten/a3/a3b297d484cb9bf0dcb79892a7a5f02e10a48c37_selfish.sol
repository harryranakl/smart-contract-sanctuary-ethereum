/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.8.0;

interface mintInterface {
    function mintsTo(uint _count, address _destination) external;
}

contract selfish{
    address public targetContract;

    mintInterface mintContract = mintInterface(targetContract);

    function setTargetContract(address _target) public{
        targetContract = _target;
    }

    function execMint(uint _mintCount) public{
        mintContract.mintsTo(_mintCount, msg.sender);
    }
}