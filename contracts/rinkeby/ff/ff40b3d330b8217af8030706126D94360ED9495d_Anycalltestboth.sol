// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags

    ) external payable;

    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
    
    function executor() external view returns (address executor);
}

  

contract Anycalltestboth{
    //real one 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89

    // The FTM testnet anycall contract
    address public anycallcontract;
    // address public anycallExecutor;
    uint destchain=4;

    address public owneraddress;

    // Our Destination contract on Rinkeby testnet
    address public receivercontract=0x0B9d284F411Aa8997c1E8286675E0ba2f6a5A4B3;
    


    address public verifiedcaller;

    
    event NewMsg(string msg);

    receive() external payable {}

    fallback() external payable {}

    constructor(address _anycallcontract){
        anycallcontract=_anycallcontract;
        owneraddress=msg.sender;
        // anycallExecutor=CallProxy(anycallcontract).executor();
    }
    
    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }
    function changedestinationcontract(address _destcontract) onlyowner external {
        receivercontract=_destcontract;
    }

    function changeverifiedcaller(address _contractcaller) onlyowner external {
        verifiedcaller=_contractcaller;
    }
    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontract).anyCall(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),
            address(0),
            destchain,

            // Using 0 flag to pay fee on destination chain
            0
            );
            
        }

    }

    function step1_initiateAnyCallSimple_srcfee(string calldata _msg) payable external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontract).anyCall{value: msg.value}(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),
            address(0),
            destchain,

            // Using 0 flag to pay fee on destination chain
            2
            );
            
        }

    }


    event ContextEvent( address indexed _from, uint256 indexed _fromChainId);

    // anyExecute has to be role controlled by onlyMPC so it's only called by MPC
   function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (string memory _msg) = abi.decode(_data, (string));  
        // (address from, uint256 fromChainId,) = CallProxy(anycallExecutor).context();
        // require(verifiedcaller == from, "AnycallClient: wrong context");
        emit NewMsg(_msg);
        // emit ContextEvent(from,fromChainId);
        success=true;
        result='';

    }

    // function checkContext() external view returns (address,address,uint256,uint256){


    //     (address from, uint256 fromChainId,uint256 nonce) = CallProxy(anycallExecutor).context();
    //     // emit NewMsg(executoraddress);
    //     // emit ContextEvent(from,fromChainId);
    //     return ( anycallExecutor,from, fromChainId,nonce);

    // }

}