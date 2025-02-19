//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;


    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address private immutable i_owner;
    //Use constant, immutable to lower the gas
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{

        // require(getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send enough!!");
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough!!");
        //18 decimals
        s_funders.push(msg.sender); //To store all sender list
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public {

        // require(msg.sender == i_owner, "Sender is not i_owner")

        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the array
        s_funders = new address[](0);

        //msg.sender = address
        //payable(msg.sender) = payable address

        //transfer
        // payable(msg.sender).transfer(address(this).balance);

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send Failed")

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner{

        address[] memory funders = s_funders;
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);

    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not i_owner");
        if(msg.sender != i_owner) { revert NotOwner(); }
        _; // doing the rest of the code
    }

    // function withdraw(){}
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){

        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e -- ETH/USD 
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        // (/*uint80 roundID*/, int price, /*uint startedAt*/, /*uint timeStamp*/, /*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        (, int256 price,,,) = priceFeed.latestRoundData();
        //ETH in terms of USD
        //3000.00000000

        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    function getVersion() internal view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}