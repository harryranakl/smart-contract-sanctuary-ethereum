/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract RPS {

    constructor () payable {}

    enum Hand {
        rock,paper,scissors
    }
    enum PlayerStatus{
        STATUS_WIN,STATUS_LOSE,STATUS_TIE,STATUS_PENDING
    }
    struct Player {
        address payable addr;
        uint256 playerBetAmout;
        Hand hand;
        PlayerStatus playerStatus;
    }
    enum GameStatus{
        STATUS_NOT_STARTED,STATUS_STARTED,STATUS_COMPLETE,STATUS_ERROR
    }
    struct Game{
        Player originator;
        Player taker;
        uint256 betAmout;
        GameStatus gameStatus;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;
    modifier isValidHand (Hand _hand) {
        require((_hand == Hand.rock)||(_hand == Hand.paper)||(_hand == Hand.scissors));
        _;
    }
    function createRoom(Hand _hand) public payable isValidHand(_hand) returns (uint roomNum){
        rooms[roomLen] = Game({
            betAmout : msg.value,
            gameStatus : GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmout : msg.value
            }),
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmout: 0
            })
        
        });
        roomNum = roomLen;
        roomLen=roomLen+1;
    }

    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand) {
        rooms[roomNum].taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmout: msg.value
        });
        rooms[roomNum].betAmout = rooms[roomNum].betAmout+msg.value;
        compareHands(roomNum);
    }
    function compareHands(uint roomNum) private {
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus=GameStatus.STATUS_STARTED;

        if(taker == originator){//tie
            rooms[roomNum].originator.playerStatus=PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus=PlayerStatus.STATUS_TIE;
        }
        else if((taker+1)%3 == originator){//origin win
            rooms[roomNum].originator.playerStatus=PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus=PlayerStatus.STATUS_LOSE;
        }
        else if((originator+1)%3 == taker){//origin win
            rooms[roomNum].originator.playerStatus=PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus=PlayerStatus.STATUS_WIN;
        }else{
            rooms[roomNum].gameStatus=GameStatus.STATUS_ERROR;
        }
    }

    function checkTotalpay(uint roomNum) public view returns(uint roomNumPay){
        return rooms[roomNum].betAmout;
    }
    modifier isPlayer (uint roomNum, address sender){
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }
    function payout(uint roomNum) public payable isPlayer(roomNum,msg.sender){
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmout);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmout);

        }else{
            if(rooms[roomNum].originator.playerStatus==PlayerStatus.STATUS_WIN){
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmout);
            }
            else if(rooms[roomNum].taker.playerStatus==PlayerStatus.STATUS_WIN){
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmout);
            }else{
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmout);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmout);
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}