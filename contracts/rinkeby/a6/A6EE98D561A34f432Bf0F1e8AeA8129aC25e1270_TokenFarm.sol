//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable
{
    address[] public allowedTokenList;
    mapping(address => mapping(address => uint256)) public stakingBalances;//token address->user address->amount
    address [] public stakersList;
    mapping (address => uint256) public uniqueTokensStaked;
    mapping (address => address) public tokenPriceFeedMapping;

    IERC20 public dappToken;

    constructor(address _dappTokenAddress)
    {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _tokenAddress, address _priceFeedAddress) public onlyOwner
    {
        tokenPriceFeedMapping[_tokenAddress] = _priceFeedAddress;
    }

    function tokenIsAllowed(address _tokenAddress) public view returns(bool)
    {
        for(uint256 idx=0; idx< allowedTokenList.length; idx++)
        {
            if (allowedTokenList[idx] == _tokenAddress)
                return true;
        }
        return false;
    }

    function addAllowedToken(address _tokenAddress) public onlyOwner
    {
        allowedTokenList.push(_tokenAddress);
    }

    function updateUniqueTokensStaked(address _owner, address _tokenAddress) internal
    {
        if (stakingBalances[_tokenAddress][_owner] <= 0) //only update uniqueTokensStaked if 
                                                         //this user has zero amount of this token staked
        {
           uniqueTokensStaked[_owner] += 1;
        }
    }

    function getTokenValue(address _tokenAddress) internal view returns(uint256,uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_tokenAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return(uint256(price),decimals);
    }

    function getSingleUserTokenValue(address _user, address _tokenAddress) public view returns(uint256)
    {
        if(uniqueTokensStaked[_user] <= 0)
            return 0;

        (uint256 price, uint256 decimals) =  getTokenValue(_tokenAddress);
        return (stakingBalances[_tokenAddress][_user] * price/10**decimals);
    }

    function getUserTotalvalue(address _user) public view returns(uint256)
    {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked");
        for(uint256 idx=0; idx<allowedTokenList.length;idx++)
        {
            totalValue += getSingleUserTokenValue(_user, allowedTokenList[idx]);
        }
        return totalValue;
    }

    function stakeToken(uint256 _amount, address _tokenAddress) public
    {
        require(_amount>0,"Amount must be greater than zero!");
        require(tokenIsAllowed(_tokenAddress), "Cannot stake this token, its not allowed");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender ,_tokenAddress);
        stakingBalances[_tokenAddress][msg.sender] += _amount;
        if (uniqueTokensStaked[msg.sender] == 1)
            stakersList.push(msg.sender);
    }

    function unstakeToken(address _tokenAddress) public
    {
        uint256 balance = stakingBalances[_tokenAddress][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_tokenAddress).transfer(msg.sender, balance);
        stakingBalances[_tokenAddress][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;
        if(uniqueTokensStaked[msg.sender] <= 0)
        {
            for(uint256 idx=0; idx < stakersList.length; idx++)
            {
                if (stakersList[idx] == msg.sender)
                {
                    stakersList[idx] = stakersList[stakersList.length-1];//copy last element in this one
                    stakersList.pop();//now delete the last element
                }
            }
        }
    }

    function issueToken() public onlyOwner
    {
        for(uint256 idx; idx < stakersList.length; idx++)
        {
            address recipient = stakersList[idx];
            uint256 userTotalValue =  getUserTotalvalue(recipient);
            dappToken.transfer(recipient,userTotalValue);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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