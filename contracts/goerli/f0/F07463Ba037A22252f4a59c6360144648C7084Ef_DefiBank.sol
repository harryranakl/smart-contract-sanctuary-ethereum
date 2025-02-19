/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: abc.sol


pragma solidity 0.8.0;


contract DefiBank {


    // address public constant Admin = ;
    address public constant USD =0x77a765bA0CfB1f25D22A6194feDcA6e1beCcd0B2;
    // address public constant soren = ;

    mapping(address => uint256) balances;
    event Deposit(address user, address token, uint256 amount);
    event WithDraw(address user, address token, uint256 amount);

    /* constructor(){

        start_time = block.timestamp;
        end_time = start_time + 7 days;
    }*/

    function deposit(uint256 amount) public payable{

        require(amount >= 100000000000000000000, 'The amount should be more than 100 USD');
        
        bool success = IERC20(USD).transferFrom(msg.sender, address(this), amount);
        require(success == true, "transfer failed!");

        balances[msg.sender] += amount;
        emit Deposit(msg.sender, USD, amount);
        
    }


    function withdraw() public payable{

        require(balances[msg.sender] > 0, 'insufficient balance');
        //require(block.timestamp >= end_time, 'too early');

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        IERC20(USD).transfer(msg.sender, balance);
        // IERC20(soren).transfer(msg.sender, balance / 100);
        emit WithDraw(msg.sender, USD, balance);
    }


    function getbalance(address user) public view returns(uint256){

        return balances[user];
    }
}