// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGnosisSettlement{
    function setPreSignature(
        bytes calldata orderUid, 
        bool signed) external;
}

contract BatchExecutor {
    
    constructor(){}

    /// @dev Validates pending transaction in the CoWSwap pool.
    /// @param orderUid The unique identifier of the order to pre-sign.
    /// @param signed Pass true to validate order.
    function sendSetSignatureTx(
        bytes calldata orderUid, 
        bool signed) 
        external
    {
        // GPv2Settlement
        address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
        IGnosisSettlement(_gnosisSettlement).setPreSignature(orderUid,signed);
    }   

    /// @dev Validates a batch of pending transactions in the CoWSwap pool.
    /// @param orderUids The list of the unique identifiers of the order to pre-sign.\
    /// @param signed Pass true to validate orders.
    function sendSetSignatureTxBatch(
        bytes[] calldata orderUids, 
        bool signed) 
        external
    {
        // GPv2Settlement
        address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
        uint len = orderUids.length;
        for (uint i = 0; i < len; i++){
            IGnosisSettlement(_gnosisSettlement).setPreSignature(orderUids[i],signed);
        }
    }   

}