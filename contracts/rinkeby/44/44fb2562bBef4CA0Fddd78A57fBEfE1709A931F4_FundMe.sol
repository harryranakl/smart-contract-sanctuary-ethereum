// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

//after solidity v0.8 this is no longer necessary, but otherwise it is good to put it in there. Even if uint256 is a big number, a uint8 (max is 255), if we sum + uint8(1) then it would reset to 0, and if we sum + uint(100) it resets and starts and gets to 99.
//this is called a "library", and is reusable code where A can be used for B, by attaching library functions (from the library A) to any type (B) in the context of a contract.
import "SafeMathChainlink.sol";

contract FundMe {
    //this library is to avoid overflows of uint256 variables, and here is how we utilize it:
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50; /* * 10 ** 18 */
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;

        //with this line  we push a funder's address to the funders[] array to keep track of which address founded how much, so that we can reset it to 0 after withdrawals.
        //If someone funds multiple times, then we will have a redundancy in the array, but we will keep it like this for now:
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * weiAmount) / 1000000000000000000;
        //both ethPrice and weiAmount come in wei units, for which we need to divide it by 10**18
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Your are not the owner of this contract, donÂ´t try to steal the funds!"
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        //"this" is a so called "keyword" in Solidity, and refers to the contract which we are currently in. By adding the onlyOwner variable on top, where we define that onlyOwner should be the one who deployed the contract, we avoid external people withdrawing funds from our contract.
        //in the start of the contract we use a "constructor" item which defines that the deployer of the contract is the owner (i.e. the initial msg.sender), and with the modifier clause above we require that only the onlyOwner can run the withdraw function
        //so in a nutshell: whoever calls this withdraw function (i.e. the msg.sender), activates a transfer task that transfers the ".balance" of this address (i.e. the address of this contract). That is why we need to ensure only the contract Admin owner (i.e. the onlyOwner) can be the msg.sender and withdraw
        msg.sender.transfer(address(this).balance);

        //logic here is is done to reset someone's balance to 0 in the array after someone withdrew:
        for (
            uint256 funderIndex = 0; /*starting value of index*/
            funderIndex < funders.length; /*loop finishes when value of index = length of the array*/
            funderIndex++ /*adds 1 every time loop finishes*/
        ) {
            //here we grab the address of the funder from the funders array (which we pushed in the fund function), and set it to 0 for each of the array addresses until funderIndex = founders.length
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}