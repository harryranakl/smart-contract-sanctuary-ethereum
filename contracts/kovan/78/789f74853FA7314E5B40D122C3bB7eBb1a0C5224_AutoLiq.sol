/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// File: contracts/interface/Compound.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface CErc20 {
  function balanceOf(address) external view returns (uint);

  function mint(uint) external returns (uint);

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow(uint) external returns (uint);

  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

  function transfer(address to, uint256 amount) external returns (bool);

  function liquidateBorrow(
    address borrower,
    uint amount,
    address collateral
  ) external returns (uint);
}

interface CEth {
  function balanceOf(address) external view returns (uint);

  function mint() external payable;

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow() external payable;
}

interface Comptroller {
  function markets(address)
    external
    view
    returns (
      bool,
      uint,
      bool
    );

  function enterMarkets(address[] calldata) external returns (uint[] memory);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint,
      uint,
      uint
    );

  function closeFactorMantissa() external view returns (uint);

  function liquidationIncentiveMantissa() external view returns (uint);

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint actualRepayAmount
  ) external view returns (uint, uint);
}

interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

// File: contracts/interface/ILendingPool.sol

pragma solidity ^0.8.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface ILendingPool {


    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;



}

// File: contracts/interface/ILendingPoolAddressesProvider.sol

pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface ILendingPoolAddressesProvider {

    function getLendingPool() external view returns (address);


}

// File: contracts/interface/IFlashLoanReceiver.sol

pragma solidity ^0.8.0;


/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function LENDING_POOL() external view returns (ILendingPool);

}

// File: contracts/FlashLoanReceiverBase.sol

pragma solidity ^0.8;



abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/AutoLiq.sol

pragma solidity 0.8.15;





contract AutoLiq is FlashLoanReceiverBase {
    using SafeMath for uint;


//    IERC20 public tokenBorrow;
//    CErc20 public cTokenBorrow;
//    CErc20 cTokenCollateral;
//    address public borrower;
    mapping(address => mapping(bytes => address)) public liquidations;

    address public owner;
    Comptroller public comptroller;
    address public uniswapRouterAddress;

    modifier onlyOwner() {
//        require(msg.sender == owner, "only owner can call this");
        _;
    }

    event LogInt(string name, uint num);
    event LogAddress(string name, address add);
    event LogString(string name, string str);



    constructor(address _aavePool, address _compoundComptroller, address _uniswapRouter)
    public
    FlashLoanReceiverBase(ILendingPoolAddressesProvider(_aavePool))
    {
        owner = msg.sender;
        comptroller = Comptroller(_compoundComptroller);
        uniswapRouterAddress = _uniswapRouter;
    }

    function beginLiquidate(address _borrower, address _tokenBorrow, address _cTokenBorrow, address _cTokenCollateral)
    public
    onlyOwner
    returns (uint)
    {
        uint repayAmount = this.getRepayAmount(_borrower, _cTokenBorrow);
        flashLoan(_borrower, _tokenBorrow, repayAmount);
        return repayAmount;
    }

    //-------------------------------FLASH_LOAN-------------------------------

    function flashLoan(address _borrower, address _tokenBorrow, uint _repayAmount) internal {
        address receiverAddress = address(this);

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        address[] memory assets = new address[](1);
        assets[0] = _tokenBorrow;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _repayAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;


        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }


    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // do stuff here (arbitrage, liquidation, etc...)
//        liquidate(amount, asset, asset, asset, asset);
        // abi.decode(params) to decode params


//
        for (uint256 i = 0; i < assets.length; i++) {
            emit LogInt("borrowed", amounts[i]);
            emit LogInt("fee", premiums[i]);
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }



    //-------------------------------LIQUIDATE-------------------------------


    function getRepayAmount(address _borrower, address _cTokenBorrow) external onlyOwner returns (uint){
        uint closeFactor = this.getCloseFactor();
        uint totalAmount = this.getBorrowBalance(_borrower, _cTokenBorrow);
        uint repayAmount = totalAmount * closeFactor / (10 ** 18) / 500;
        emit LogInt("repayAmount", repayAmount);
        return repayAmount;
    }


    function getBorrowBalance(address _borrower, address _cTokenBorrow) external onlyOwner returns (uint) {
        return CErc20(_cTokenBorrow).borrowBalanceCurrent(_borrower);
    }

    // close factor
    function getCloseFactor() external view returns (uint) {
        return comptroller.closeFactorMantissa();
    }

    // autoLiquidate
    function autoLiquidate(address _borrower, address _tokenBorrow,address _cTokenBorrow, address _cTokenCollateral) public returns (uint){

        uint repayAmount = this.getRepayAmount(_borrower, _tokenBorrow);

        IERC20(_tokenBorrow).transferFrom(msg.sender, address(this), repayAmount);
        IERC20(_tokenBorrow).approve(_cTokenBorrow, repayAmount);
        uint code = CErc20(_cTokenBorrow).liquidateBorrow(_borrower, repayAmount, _cTokenCollateral);
        require(
            code == 0,
            "liquidate failed"
        );

        transferOut(_cTokenCollateral);
        return code;
    }

    function getAccountLiquidity(address _borrower)
    external
    view
    returns (uint liquidity, uint shortfall)
    {
        // liquidity and shortfall in USD scaled up by 1e18
        (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(
            _borrower
        );
        require(error == 0, "getAccountLiquidity error");
        return (_liquidity, _shortfall);
    }


    // get amount of collateral to be liquidated
    function getAmountToBeLiquidated(
        address _cTokenBorrow,
        address _cTokenCollateral,
        uint _actualRepayAmount
    ) external view returns (uint) {

        (uint error, uint cTokenCollateralAmount) = comptroller
        .liquidateCalculateSeizeTokens(
            _cTokenBorrow,
            _cTokenCollateral,
            _actualRepayAmount
        );

        require(error == 0, "error");

        return cTokenCollateralAmount;
    }


    // liquidate
    function liquidate(
        uint _repayAmount,
        address _borrower,
        address _tokenBorrow,
        address _cTokenBorrow,
        address _cTokenCollateral
    ) onlyOwner internal {

        //授权cTokenBorrow可划转tokenBorrow的额度为repayAmount
        IERC20(_tokenBorrow).approve(_cTokenBorrow, _repayAmount);

        require(
            CErc20(_cTokenBorrow).liquidateBorrow(_borrower, _repayAmount, _cTokenCollateral) == 0,
            "liquidate failed"
        );

        transferOut(_cTokenCollateral);
    }

    function transferOut(address _cTokenCollateral) onlyOwner internal {
        CErc20 cTokenCollateral = CErc20(_cTokenCollateral);

        uint amount = cTokenCollateral.balanceOf(address(this));
        cTokenCollateral.redeem(amount);

        bool success = cTokenCollateral.transfer(tx.origin, amount);

        require(
            success == true,
            "transfer failed"
        );
    }
}