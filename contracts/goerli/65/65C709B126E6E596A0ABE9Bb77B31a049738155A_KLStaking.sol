/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IKLToken is IERC20 {

    function mint(address owner,uint256 amount) external;

    function burn(address owner,uint256 amount) external;

}


contract KLStaking is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IKLToken;

    // 支持ERC20代币质押
    struct Token {
        bool multiple;      // 是否质押数量必须是节点最大质押量的倍数(默认为true)
        uint32 numerator;   // 兑换比例分子（默认1）
        uint32 denominator; // 兑换比例的分母（默认1）
        IERC20 input;       // 质押代币合约地址（ETH、USDT、DAI....）
        IKLToken output;    // 生成锚定币合约地址（KLETH、KLUSDT、KLDAI....）
        uint256 minimum;    // 节点最小质押数量(默认32 = 32 * 1e18)
        uint256 maximum;    // 节点最大质押数量(默认32 = 32 * 1e18)
    }

    // 质押订单
    struct Order {
        uint8 status;       // 质押状态（ 0: deposit  1: staked  2: unstaked  3: withdrawal  4: staking  5: unstaking ）
        uint256 amount;     // 质押数量
    }

    // 系统设置
    struct Setting {
        bool locked;        // 是否锁定合约（默认false，锁定后充值、提现均无法操作）
        address server;     // 服务端操作地址
        address manager;    // 管理员操作地址
        address funds;      // 资金管理地址
    }

    // 可质押代币合约列表（ETH、USDT、DAI....）
    mapping(string => Token) private _tokens;

    // 质押订单状态
    mapping(uint256 => address) private _stakeUsers;
    mapping(uint256 => Order) private _stakeOrders;

    // 初始化变量
    Setting private _settings;
    uint256 private _identity;

    // 存款事件
    event OnDeposit(address indexed sender, address indexed token, uint256 indexed id, uint256 time, uint256 staked, uint256 issued);

    // 提款事件
    event OnWithdraw(address indexed sender, address indexed token, uint256 indexed id, uint256 time, uint256 burned, uint256 returned);

    // 转移事件
    event OnTransfer(address indexed sender, address indexed token, uint256[] ids, uint256 time, uint256 amount);

    // 更新订单事件
    event OnUnstake(address indexed sender, address indexed token, uint256[] ids, uint256 time, uint256 amount);

    // 修改代币事件
    event OnChangeToken(string indexed name, address indexed input, address indexed output, bool multiple, uint32 numerator, uint32 denominator, uint256 minimum, uint256 maximum);

    // 移除代币事件
    event OnRemoveToken(string indexed name);

    // 系统设置事件
    event OnChangeSetting(bool locked, address server, address manager, address funds);

    // 锁定事件
    event OnChangeLock(bool locked);


    constructor(address funds, address server, address manager){
        _settings.locked = false;
        _settings.funds = funds;
        _settings.server = server;
        _settings.manager = manager;
    }

    // 质押代币获得锚定币（用户操作）
    function deposit(string memory name, uint256 amount) public payable nonReentrant {

        require(_settings.locked==false, "The system is currently under maintenance");

        // 判断代币存在
        Token memory token = _tokens[name];
        require(token.numerator>=1, "The token does not exists");

        // 验证质押数量（地址为0则认为ETH质押，反之则认为ERC20代币质押）
        if(address(token.input) == address(0)){
            amount = msg.value;
        }else{
            token.input.safeTransferFrom(msg.sender, address(this), amount); 
        }
        require(amount >= token.minimum, "The amount cannot be less than minimum");

        // 验证质押倍数
        uint256 remain = amount % token.maximum;
        if(token.multiple==true){
            require(remain == 0, "Invalid multiple amount");
        }

        // 创建倍数订单
         uint256 count = amount.div(token.maximum);
        for(uint i=0;i<count;i++){
            _identity = _identity.add(1);
            _stakeUsers[_identity] = msg.sender;
            _stakeOrders[_identity] = Order(0,amount);
            emit OnDeposit(msg.sender, address(token.input), _identity, block.timestamp, token.maximum, token.maximum.mul(token.numerator).div(token.denominator));
        }

        // 创建余数订单
        if(remain>0){
            _identity = _identity.add(1);
            _stakeUsers[_identity] = msg.sender;
            _stakeOrders[_identity] = Order(0,amount);
            emit OnDeposit(msg.sender, address(token.input), _identity, block.timestamp, remain, remain.mul(token.numerator).div(token.denominator));
        }
        
        // 发行锚定币
        uint256 issued = amount.mul(token.numerator).div(token.denominator);
        token.output.mint(msg.sender, issued);
    }

    // 提取代币并销毁锚定币（用户操作）
    function withdraw(string memory name, uint256 id) public nonReentrant {

        require(_settings.locked==false, "The system is currently under maintenance");

        // 判断代币存在
        Token memory token = _tokens[name];
        Order storage order = _stakeOrders[id];
        require(token.numerator>=1, "The token does not exists");
        require(_stakeUsers[id] == msg.sender, "Invalid owner");
        require(order.status == 0 || order.status == 2, "You cannot withdraw tokens right now");// 0:deposit 2:unstaked 状态才能提现

        // 验证质押数量（地址为0则认为退还ETH代币，反之则认为退还ERC20代币）
        bool isEthToken = address(token.input) == address(0);
        if(isEthToken){
            uint balance = address(this).balance;
            require(balance>=order.amount,"Insufficient balance");
        }else{
            uint balance = token.input.balanceOf(address(this));
            require(balance>=order.amount,"Insufficient balance");
        }

        // 转移锚定币
        uint256 burned = order.amount.mul(token.numerator).div(token.denominator);
        token.output.safeTransferFrom(msg.sender, address(this), burned); 
        order.status = 3; // 3: withdrawal

        // 发送质押币
        if(isEthToken){
            (bool success,) = msg.sender.call{value: order.amount}("");
            require(success);
        }else{
            token.input.safeTransfer(msg.sender,order.amount);
        }

        // 销毁锚定币
        token.output.burn(address(this), order.amount);
        
        emit OnWithdraw(msg.sender, address(token.input), id, block.timestamp, burned, order.amount);
    }

    // 系统转移质押代币并创建节点（系统服务操作）
    function transfer(string memory name, uint256[] memory ids) public nonReentrant {
        
        Token memory token = _tokens[name];
        require(token.numerator>=1, "The token does not exists");
        require(ids.length>0,"Invalid id");
        require(_settings.funds!=address(0),"Invalid funds address");
        require(_settings.server==msg.sender,"Invalid server address");

        // 计算总转移数量，修改用户质押状态（0: deposit  1: staked  2: unstaked  3: withdrawal  4: staking  5: unstaking ）
        uint256 amount = 0;
        for(uint i=0;i<ids.length;i++){
            amount = amount.add(_stakeOrders[ids[i]].amount);
            _stakeOrders[ids[i]].status = 4;// 4:staking
        }

        // 转移代币至资金地址（地址为0则认为转移ETH代币，反之则认为转移ERC20代币）
        bool isEthToken = address(token.input) == address(0);
        if(isEthToken){
            uint balance = address(this).balance;
            require(balance>=amount,"Insufficient balance");
            (bool success,) = _settings.funds.call{value: amount}("");
            require(success);
        }else{
            uint balance = token.input.balanceOf(address(this));
            require(balance>=amount,"Insufficient balance");
            token.input.safeTransfer(_settings.funds,amount);
        }

        emit OnTransfer(msg.sender, address(token.input), ids, block.timestamp, amount);
    }

    // 更新订单状态为取消质押（系统服务操作）
    function unstake(string memory name, uint256[] memory ids) public nonReentrant {
        
        Token memory token = _tokens[name];
        require(token.numerator>=1, "The token does not exists");
        require(ids.length>0,"Invalid id");
        require(_settings.server==msg.sender,"Invalid server address");

        // 修改用户质押状态（0: deposit  1: staked  2: unstaked  3: withdrawal  4: staking  5: unstaking ）
        uint256 amount = 0;
        for(uint i=0;i<ids.length;i++){
            amount = amount.add(_stakeOrders[ids[i]].amount);
            _stakeOrders[ids[i]].status = 2;// 2:unstaked
        }

        emit OnUnstake(msg.sender, address(token.input), ids, block.timestamp, amount);
    }

    // 创建质押代币（管理员操作）
    function changeToken(string memory name, bool multiple, uint32 numerator, uint32 denominator, address input, address output, uint256 minimum, uint256 maximum) public {

        Token storage token = _tokens[name];
        require(bytes(name).length>0,"Invalid name");
        require(numerator >= 1,"Invalid numerator");
        require(denominator >= 1,"Invalid denominator");
        require(output != address(0),"Invalid output address");
        require(minimum >0,"Invalid minimum");
        require(maximum >0,"Invalid maximum");
        require(_settings.manager == msg.sender,"Error manager");

        token.multiple = multiple;
        token.numerator = numerator;
        token.denominator = denominator;
        token.input = IERC20(input);
        token.output = IKLToken(output);
        token.minimum = minimum;
        token.maximum = maximum;
        
        emit OnChangeToken(name,address(input),address(output),multiple,numerator,denominator,minimum,maximum);
    }

    // 移除质押代币（管理员操作）
    function removeToken(string memory name) public {
        Token storage token = _tokens[name];
        require(token.numerator>=1,"Token does not exists");
        require(_settings.manager == msg.sender,"Error manager");
        delete _tokens[name];
        emit OnRemoveToken(name);
    }

    // 修改系统设置（管理员操作）
    function changeSetting(bool locked, address server, address manager, address funds) public {
        require(_settings.manager == msg.sender,"Error manager");
        _settings = Setting(locked, server, manager, funds);
        emit OnChangeSetting(locked, server, manager, funds);
    }

    // 锁定系统状态（管理员操作）
    function lock() public {
        _settings.locked = !_settings.locked;
        emit OnChangeLock(_settings.locked);
    }

    // 一键紧急提现(dev)
    function emergency(string memory name) public {
        Token memory token = _tokens[name];
        require(token.numerator>=1, "The token does not exists");

        bool isEthToken = address(token.input) == address(0);
        if(isEthToken){
            uint balance = address(this).balance;
            (bool success,) = _settings.funds.call{value: balance}("");
            require(success);
        }else{
            uint balance = token.input.balanceOf(address(this));
            token.input.safeTransfer(_settings.funds,balance);
        }
    }
    
    // 获取系统信息
    function getSettingInfo() public view returns (Setting memory setting) {
        setting = _settings;
    }

    // 获取代币信息
    function getTokenInfo(string memory name) public view returns (Token memory token) {
        token = _tokens[name];
    }
    
    // 获取订单信息
    function getOrderInfo(uint256 id) public view returns (Order memory order) {
        order = _stakeOrders[id];
    }
}