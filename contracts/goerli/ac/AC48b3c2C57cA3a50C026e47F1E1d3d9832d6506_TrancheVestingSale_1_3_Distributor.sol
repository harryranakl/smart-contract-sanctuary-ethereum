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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Distributor } from "./abstract/Distributor.sol";
import { TrancheVesting } from "./abstract/TrancheVesting.sol";
import { MerkleSet } from "./abstract/MerkleSet.sol";
import { SaleManager_v_1_3 } from "../sale/v1.3/SaleManager.sol";

abstract contract IERC20WithDecimals is IERC20 {
  function decimals() public view virtual returns (uint8);
}

contract TrancheVestingSale_1_3_Distributor is
  Distributor,
  TrancheVesting,
  ReentrancyGuard
{
  SaleManager_v_1_3 public immutable saleManager;
  bytes32 public immutable saleId;

  modifier validSaleParticipant(address beneficiary) {
    require(saleManager.getSpent(saleId, beneficiary) > 0, "no purchases found");

    _;
  }

  constructor(
    SaleManager_v_1_3 _saleManager, // where the purchase occurred
    bytes32 _saleId, // the sale id
    IERC20 _token, // the purchased token to distribute
    Tranche[] memory tranches, // vesting tranches
    uint256 voteWeightBips,
    string memory uri // information on the sale (e.g. merkle proofs)
  )
    TrancheVesting(tranches)
    // initialize the distributor with the total purchased quantity from the sale
    Distributor(_token, _saleManager.spentToBought(_saleId, _saleManager.getTotalSpent(_saleId)), voteWeightBips, uri)
  {
    require(address(_saleManager) != address(0), "TVS_1_3_D: sale is address(0)");
    require(_saleId != bytes32(0), "TVS_1_3_D: sale id is bytes(0)");

    // if the ERC20 token provides decimals, ensure they match 
    int decimals = tryDecimals(_token);
    require(decimals == -1 || decimals == int(_saleManager.getDecimals(_saleId)), "token decimals do not match sale");
    require(_saleManager.isOver(_saleId), "TVS_1_3_D: sale not over");

    saleManager = _saleManager;
    saleId = _saleId;
  }

  function NAME() external override virtual pure returns (string memory) {
    return 'TrancheVestingSale_1_3_Distributor';
  }
  
  // File specific version - starts at 1, increments on every solidity diff
  function VERSION() external override virtual pure returns (uint) {
    return 3;
  }

  function tryDecimals(IERC20 _token) internal view returns (int) {
      try IERC20WithDecimals(address(_token)).decimals() returns (uint8 decimals) {
        return int(uint(decimals));
      } catch {
        return -1;
      }
  }

  function getPurchasedAmount(address buyer) public view returns (uint256) {
    /**
    Get the purchased token quantity from the sale
  
    Example: if a user buys $1.11 of a FOO token worth $0.50 each, the purchased amount will be 2.22 FOO
    Returns purchased amount: 2220000 (2.22 with 6 decimals)
    */
    return saleManager.getBought(saleId, buyer);
  }

  function initializeDistributionRecord(
    address beneficiary // the address that will receive tokens
  ) validSaleParticipant(beneficiary) external {
    _initializeDistributionRecord(beneficiary, getPurchasedAmount(beneficiary));
  }

  function claim(
    address beneficiary // the address that will receive tokens
  ) external validSaleParticipant(beneficiary) nonReentrant {
    uint256 amount = getClaimableAmount(beneficiary);

    if (!records[beneficiary].initialized) {
      _initializeDistributionRecord(beneficiary, getPurchasedAmount(beneficiary));
    }

    super._executeClaim(beneficiary, amount);
  }

  function getDistributionRecord(address beneficiary) external override view returns (DistributionRecord memory) {
    DistributionRecord memory record = records[beneficiary];

  // workaround prior to initialization
    if (!record.initialized) {
      record.total = uint120(getPurchasedAmount(beneficiary));
    }
    return record;
  }

  // get the number of tokens currently claimable by a specific user
  function getClaimableAmount(address beneficiary) public override view returns (uint256) {
    if (records[beneficiary].initialized) return super.getClaimableAmount(beneficiary);

    // we can get the claimable amount prior to initialization
    return getPurchasedAmount(beneficiary) * _getVestedBips(beneficiary, block.timestamp) / 10000;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVotesLite } from "../interfaces/IVotesLite.sol";

abstract contract Distributor is IVotesLite {
  using SafeERC20 for IERC20;

  event InitializeDistributor(IERC20 indexed token, uint256 total, uint256 weightBips, string uri);
  event InitializeDistributionRecord(address indexed beneficiary, uint256 amount);
  event Claim(address indexed beneficiary, uint256 amount);

  struct DistributionRecord {
    bool initialized; // has the claim record been initialized
    uint120 total; // total token quantity claimable
    uint120 claimed; // token quantity already claimed
  }

  mapping (address => DistributionRecord) internal records; // track distribution records per user
  IERC20 public immutable token; // the token being claimed 
  uint256 public total; // total tokens allocated for claims
  uint256 public claimed; // tokens already claimed
  string public uri; // ipfs link on distributor info
  uint256 private immutable weightBips; // voting weight in basis points (15000 = 1.5x factor)

  // provide context on the contract name and version
  function NAME() external virtual returns (string memory);
  function VERSION() external virtual returns (uint);

  constructor (
    IERC20 _token,
    uint256 _total,
    uint256 _weightBips,
    string memory _uri
  ) {
    require(address(_token) != address(0), "Distributor: token is address(0)");
    require(_total > 0, "Distributor: total is 0");

    token = _token;
    total = _total;
    weightBips = _weightBips;
    uri = _uri;
    emit InitializeDistributor(token, total, weightBips, uri);
  }

  function _initializeDistributionRecord(address beneficiary, uint256 amount) internal {
    // CALLER MUST VERIFY THE BENEFICIARY AND AMOUNT ARE VALID!

    // Checks
    require(amount <= type(uint120).max, "Distributor: total > type(uint120).max");
	  require(!records[beneficiary].initialized, "Distributor: already initialized");

    // Effects
	  records[beneficiary] = DistributionRecord(true, uint120(amount), 0);
    emit InitializeDistributionRecord(beneficiary, amount);
  }

  function _executeClaim(address beneficiary, uint256 _amount) internal {
    // Checks: NONE! THIS FUNCTION DOES NOT CHECK PERMISSIONS: CALLER MUST VERIFY THE CLAIM IS VALID!
    uint120 amount = uint120(_amount);
    require(amount > 0, "Distributor: no more tokens claimable right now");

    // effects
	  records[beneficiary].claimed += amount;
	  claimed += amount;

    // interactions
    token.safeTransfer(beneficiary, amount);
    emit Claim(beneficiary, amount);
  }

  function getVotes(
    address beneficiary
  ) external override view returns (uint256) {
    // Uninitialized claims will not have any votes! (returns 0)

    // The user can vote using tokens that are allocated to them but not yet claimed
    return (records[beneficiary].total - records[beneficiary].claimed) * weightBips / 10000;
  }

  function getVoteWeightBips(address /*beneficiary*/) external view returns (uint256) {
    return weightBips;
  }

  function getDistributionRecord(address beneficiary) external view virtual returns (DistributionRecord memory) {
    return records[beneficiary];
  }

  // Get the fraction of tokens as basis points
  function _getVestedBips(address beneficiary, uint time) public view virtual returns (uint256);

  // get the number of tokens currently claimable by a specific user
  function getClaimableAmount(address beneficiary) public view virtual returns (uint256) {
    require(records[beneficiary].initialized, "Distributor: claim not initialized");

    DistributionRecord memory record = records[beneficiary];

    uint256 claimable = record.total * _getVestedBips(beneficiary, block.timestamp) / 10000;
    return record.claimed >= claimable
      ? 0 // no more tokens to claim
      : claimable - record.claimed; // claim all available tokens
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleSet {
  event InitializeMerkleSet(address account, uint256 amount);

  bytes32 public immutable merkleRoot;
  constructor(bytes32 _merkleRoot) {
    merkleRoot = _merkleRoot;
  }

  function _testMembership(bytes32 leaf, bytes32[] calldata merkleProof)
    internal
    view returns (bool)
  {
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  function _verifyMembership(bytes32 leaf, bytes32[] calldata merkleProof)
    internal
    view
  {
    require(_testMembership(leaf, merkleProof), "invalid proof");
  }

  modifier validMerkleProof(
    uint256 index, // the beneficiary's index in the merkle root
    address beneficiary, // the address that will receive tokens
    uint256 amount, // the total claimable by this beneficiary
    bytes32[] calldata merkleProof
  ) {
    // the merkle leaf encodes the total claimable: the amount claimed in this call is determined by _getVestedFraction()
    bytes32 leaf = keccak256(abi.encodePacked(index, beneficiary, amount));
    _verifyMembership(leaf, merkleProof);

    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Distributor } from "./Distributor.sol";

abstract contract TrancheVesting is Distributor {
  // time and vested fraction must monotonically increase in the tranche array
  struct Tranche {
    uint128 time; // block.timestamp upon which the tranche vests 
    uint128 vestedBips; // fraction of tokens unlockable as basis points (e.g. 100% of vested tokens is 10000)
  }

  Tranche[] public tranches;

  constructor(
    Tranche[] memory _tranches
  ) {
    require(_tranches.length > 0, "tranches required");

    uint128 lastTime = 0;
    uint128 lastVestedBips = 0;
  
    for (uint i = 0; i < _tranches.length; i++) {
      require(_tranches[i].vestedBips > 0, "tranche vested fraction == 0");
      require(_tranches[i].time > lastTime, "tranche time must increase");
      require(_tranches[i].vestedBips > lastVestedBips, "tranche vested fraction must increase");
      lastTime = _tranches[i].time;
      lastVestedBips = _tranches[i].vestedBips;
      tranches.push(_tranches[i]);
    }

    require(lastTime <= 4102444800, "vesting ends after 4102444800 (Jan 1 2100)");
    require(lastVestedBips == 10000, "last tranche must vest all tokens");
  }

  function _getVestedBips(address /*beneficiary*/, uint time) public override view returns (uint256) {
    for (uint i = tranches.length; i > 0; i--) {
      if (time > tranches[i - 1].time) {
        return tranches[i - 1].vestedBips;
      }
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
interface IVotesLite {
    // an account's current voting power
    function getVotes(address account) external view returns (uint256);
    // a weighting factor used to convert token holdings to voting power (in basis points)
    function getVoteWeightBips(address account) external view returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SaleManager_v_1_3 is ReentrancyGuard, PullPayment {
  using SafeERC20 for IERC20;

  AggregatorV3Interface priceOracle;
  IERC20 public immutable paymentToken;
  uint8 public immutable paymentTokenDecimals;

  struct Sale {
    address payable recipient; // the address that will receive sale proceeds
    address admin; // the address administering the sale
    bytes32 merkleRoot; // the merkle root used for proving access
    address claimManager; // address where purchased tokens can be claimed (optional)
    uint256 saleBuyLimit;  // max tokens that can be spent in total
    uint256 userBuyLimit;  // max tokens that can be spent per user
    uint256 purchaseMinimum; // minimum tokens that can be spent per purchase
    uint startTime; // the time at which the sale starts (seconds past the epoch)
    uint endTime; // the time at which the sale will end, regardless of tokens raised (seconds past the epoch)
    string uri; // reference to off-chain sale configuration (e.g. IPFS URI)
    uint256 price; // the price of the asset (eg if 1.0 NCT == $1.23 of USDC: 1230000)
    uint8 decimals; // the number of decimals in the asset being sold, e.g. 18
    uint256 totalSpent; // total purchases denominated in payment token
    uint256 maxQueueTime; // what is the maximum length of time a user could wait in the queue after the sale starts?
    uint160 randomValue; // reasonably random value: xor of merkle root and blockhash for transaction setting merkle root
    mapping(address => uint256) spent;
  }

  // this struct has two many members for a public getter
  mapping (bytes32 => Sale) private sales;

  // global metrics
  uint256 public saleCount = 0;
  uint256 public totalSpent = 0;

  // public version
  string public constant VERSION = '1.3';

  event NewSale(
    bytes32 indexed saleId,
    bytes32 indexed merkleRoot,
    address indexed recipient,
    address admin,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint256 purchaseMinimum,
    uint256 maxQueueTime,
    uint startTime,
    uint endTime,
    string uri,
    uint256 price,
    uint8 decimals
  );

  event Deploy(address paymentToken, uint8 paymentTokenDecimals, address priceOracle);
  event UpdateStart(bytes32 indexed saleId, uint startTime);
  event UpdateEnd(bytes32 indexed saleId, uint endTime);
  event UpdateMerkleRoot(bytes32 indexed saleId, bytes32 merkleRoot);
  event UpdateMaxQueueTime(bytes32 indexed saleId, uint256 maxQueueTime);
  event Buy(bytes32 indexed saleId, address indexed buyer, uint256 value, bool native, bytes32[] proof);
  event RegisterClaimManager(bytes32 indexed saleId, address indexed claimManager);
  event UpdateUri(bytes32 indexed saleId, string uri);

  constructor(
    address _paymentToken,
    uint8 _paymentTokenDecimals,
    address _priceOracle
  ) payable {
    paymentToken = IERC20(_paymentToken);
    paymentTokenDecimals = _paymentTokenDecimals;
    priceOracle = AggregatorV3Interface(_priceOracle);
    emit Deploy(_paymentToken, _paymentTokenDecimals, _priceOracle);
  }

  modifier validSale (bytes32 saleId) {
    // if the admin is address(0) there is no sale struct at this saleId
    require(
      sales[saleId].admin != address(0),
      "invalid sale id"
    );
    _;
  }

  modifier isAdmin(bytes32 saleId) {
    // msg.sender is never address(0) so this handles uninitialized sales
    require(
      sales[saleId].admin == msg.sender,
      "must be admin"
    );
    _;
  }

  modifier canAccessSale(bytes32 saleId, bytes32[] calldata proof) {
    // make sure the buyer is an EOA
    require((msg.sender == tx.origin), "Must buy with an EOA");

    // If the merkle root is non-zero this is a private sale and requires a valid proof
    if (sales[saleId].merkleRoot != bytes32(0)) {
      require(
        this._isAllowed(
          sales[saleId].merkleRoot,
          msg.sender,
          proof
        ) == true,
        "bad merkle proof for sale"
      );
    }

    // Reduce congestion by randomly assigning each user a delay time in a virtual queue based on comparing their address and a random value
    // if sale.maxQueueTime == 0 the delay is 0
    require(block.timestamp - sales[saleId].startTime > getFairQueueTime(saleId, msg.sender), "not your turn yet");

    _;
  }

  modifier requireOpen(bytes32 saleId) {
    require(block.timestamp > sales[saleId].startTime, "sale not started yet");
    require(block.timestamp < sales[saleId].endTime, "sale ended");
    require(sales[saleId].totalSpent < sales[saleId].saleBuyLimit, "sale over");
    _;
  }

  // Get current price from chainlink oracle
  function getLatestPrice() public view returns (uint) {
    (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceOracle.latestRoundData();

    require(price > 0, "negative price");
    return uint(price);
  }

  // Accessor functions
  function getAdmin(bytes32 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].admin);
  }

  function getRecipient(bytes32 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].recipient);
  }

  function getMerkleRoot(bytes32 saleId) public validSale(saleId) view returns(bytes32) {
    return(sales[saleId].merkleRoot);
  }

  function getPriceOracle() public view returns(address) {
    return address(priceOracle);
  }

  function getClaimManager(bytes32 saleId) public validSale(saleId) view returns(address) {
    return (sales[saleId].claimManager);
  }


  function getSaleBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].saleBuyLimit);
  }

  function getUserBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].userBuyLimit);
  }

  function getPurchaseMinimum(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].purchaseMinimum);
  }

  function getStartTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].startTime);
  }

  function getEndTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].endTime);
  }

  function getUri(bytes32 saleId) public validSale(saleId) view returns(string memory) {
    return sales[saleId].uri;
  }

  function getPrice(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].price);
  }

  function getDecimals(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].decimals);
  }

  function getTotalSpent(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].totalSpent);
  }

  function getRandomValue(bytes32 saleId) public validSale(saleId) view returns(uint160) {
    return sales[saleId].randomValue;
  }

  function getMaxQueueTime(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return sales[saleId].maxQueueTime;
  }

  function generateRandomishValue(bytes32 merkleRoot) public view returns(uint160) {
    /**
      Generate a randomish numeric value in the range [0, 2 ^ 160 - 1]

      This is not a truly random value:
      - miners can alter the previous block's hash by holding the transaction in the mempool
      - admins can choose when to submit the transaction
      - admins can repeatedly call setMerkleRoot()
    */
    return uint160(uint256(blockhash(block.number - 1))) ^ uint160(uint256(merkleRoot));
  }

  function getFairQueueTime(bytes32 saleId, address buyer) public validSale(saleId) view returns(uint) {
    /**
      Get the delay in seconds that a specific buyer must wait after the sale begins in order to buy tokens in the sale

      Buyers cannot exploit the fair queue when:
      - The sale is private (merkle root != bytes32(0))
      - Each eligible buyer gets exactly one address in the merkle root

      Although miners and admins can minimize the delay for an arbitrary address, these are not significant threats
      - the economic opportunity to miners is zero or relatively small (only specific addresses can participate in private sales, and a better queue postion does not imply high returns)
      - admins can repeatedly set merkle roots (but admins already control the tokens being sold!)

    */
    if (sales[saleId].maxQueueTime == 0) {
      // there is no delay: all addresses may participate immediately
      return 0;
    }

    // calculate a distance between the random value and the user's address using the XOR distance metric (c.f. Kademlia)
    uint160 distance = uint160(buyer) ^ sales[saleId].randomValue;

    // calculate a speed at which the queue is exhausted such that all users complete the queue by sale.maxQueueTime
    uint160 distancePerSecond = type(uint160).max / uint160(sales[saleId].maxQueueTime);
    // return the delay (seconds)
    return distance / distancePerSecond;
  }

  function spentToBought(bytes32 saleId, uint256 spent) public view returns (uint256) {
    // Convert tokens spent (e.g. 10,000,000 USDC = $10) to tokens bought (e.g. 8.13e18) at a price of $1.23/NCT
    // convert an integer value of tokens spent to an integer value of tokens bought
    return (spent * 10 ** sales[saleId].decimals ) / (sales[saleId].price);
  }

  function nativeToPaymentToken(uint256 nativeValue) public view returns (uint256) {
    // convert a payment in the native token (eg ETH) to an integer value of the payment token
    return (nativeValue * getLatestPrice() * 10 ** paymentTokenDecimals) / (10 ** (priceOracle.decimals() + 18));
  }

  function getSpent(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount spent by this user in paymentToken
    return(sales[saleId].spent[userAddress]);
  }

  function getBought(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount bought by this user in the new token being sold
    return(spentToBought(saleId, sales[saleId].spent[userAddress]));
  }

  function isOpen(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale currently open?
    return(
      block.timestamp > sales[saleId].startTime
      && block.timestamp < sales[saleId].endTime
      && sales[saleId].totalSpent < sales[saleId].saleBuyLimit
    );
  }

  function isOver(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale permanently over?
    return(
      block.timestamp >= sales[saleId].endTime || sales[saleId].totalSpent >= sales[saleId].saleBuyLimit
    );
  }

  /**
  sale setup and config
  - the address calling this method is the admin: only the admin can change sale configuration
  - all payments are sent to the the recipient
  */
  function newSale(
    address payable recipient,
    bytes32 merkleRoot,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint256 purchaseMinimum,
    uint startTime,
    uint endTime,
    uint160 maxQueueTime,
    string memory uri,
    uint256 price,
    uint8 decimals
  ) public returns(bytes32) {
    require(recipient != address(0), "recipient must not be zero address");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(startTime < endTime, "sale must start before it ends");
    require(endTime > block.timestamp, "sale must end in future");
    require(userBuyLimit <= saleBuyLimit, "userBuyLimit cannot exceed saleBuyLimit");
    require(purchaseMinimum <= userBuyLimit, "purchaseMinimum cannot exceed userBuyLimit");
    require(userBuyLimit > 0, "userBuyLimit must be > 0");
    require(saleBuyLimit > 0, "saleBuyLimit must be > 0");
    require(endTime - startTime > maxQueueTime, "sale must be open for longer than max queue time");

    // Generate a reorg-resistant sale ID
    bytes32 saleId = keccak256(abi.encodePacked(
      merkleRoot,
      recipient,
      saleBuyLimit,
      userBuyLimit,
      purchaseMinimum,
      startTime,
      endTime,
      uri,
      price,
      decimals
    ));

    // This ensures the Sale struct wasn't already created (msg.sender will never be the zero address)
    require(sales[saleId].admin == address(0), "a sale with these parameters already exists");

    Sale storage s = sales[saleId];

    s.merkleRoot = merkleRoot;
    s.admin = msg.sender;
    s.recipient = recipient;
    s.saleBuyLimit = saleBuyLimit;
    s.userBuyLimit = userBuyLimit;
    s.purchaseMinimum = purchaseMinimum;
    s.startTime = startTime;
    s.endTime = endTime;
    s.price = price;
    s.decimals = decimals;
    s.uri = uri;
    s.maxQueueTime = maxQueueTime;
    s.randomValue = generateRandomishValue(merkleRoot);

    saleCount++;

    emit NewSale(
      saleId,
      s.merkleRoot,
      s.recipient,
      s.admin,
      s.saleBuyLimit,
      s.userBuyLimit,
      s.purchaseMinimum,
      s.maxQueueTime,
      s.startTime,
      s.endTime,
      s.uri,
      s.price,
      s.decimals
    );

    return saleId;
  }

  function setStart(bytes32 saleId, uint startTime) public validSale(saleId) isAdmin(saleId) {
    // admin can update start time until the sale starts
    require(block.timestamp < sales[saleId].endTime, "disabled after sale close");
    require(startTime < sales[saleId].endTime, "sale start must precede end");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(sales[saleId].endTime - startTime > sales[saleId].maxQueueTime, "sale must be open for longer than max queue time");

    sales[saleId].startTime = startTime;
    emit UpdateStart(saleId, startTime);
  }

  function setEnd(bytes32 saleId, uint endTime) public validSale(saleId) isAdmin(saleId){
    // admin can update end time until the sale ends
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    require(endTime > block.timestamp, "sale must end in future");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(sales[saleId].startTime < endTime, "sale must start before it ends");
    require(endTime - sales[saleId].startTime > sales[saleId].maxQueueTime, "sale must be open for longer than max queue time");

    sales[saleId].endTime = endTime;
    emit UpdateEnd(saleId, endTime);
  }

  function setMerkleRoot(bytes32 saleId, bytes32 merkleRoot) public validSale(saleId) isAdmin(saleId){
    require(!isOver(saleId), "cannot set merkle root once sale is over");
    sales[saleId].merkleRoot = merkleRoot;
    sales[saleId].randomValue = generateRandomishValue(merkleRoot);
    emit UpdateMerkleRoot(saleId, merkleRoot);
  }

  function setMaxQueueTime(bytes32 saleId, uint160 maxQueueTime) public validSale(saleId) isAdmin(saleId) {
    // the queue time may be adjusted after the sale begins
    require(sales[saleId].endTime > block.timestamp, "cannot adjust max queue time after sale ends");
    sales[saleId].maxQueueTime = maxQueueTime;
    emit UpdateMaxQueueTime(saleId, maxQueueTime);
  }

  function setUriAndMerkleRoot(bytes32 saleId, bytes32 merkleRoot, string calldata uri) public validSale(saleId) isAdmin(saleId) {
    sales[saleId].uri = uri;
    setMerkleRoot(saleId, merkleRoot);
    emit UpdateUri(saleId, uri);
  }

  function _isAllowed(
      bytes32 root,
      address account,
      bytes32[] calldata proof
  ) external pure returns (bool) {
    // check if the account is in the merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(account));
    if (MerkleProof.verify(proof, root, leaf)) {
      return true;
    }
    return false;
  }

  // pay with the payment token (eg USDC)
  function buy(
    bytes32 saleId,
    uint256 tokenQuantity,
    bytes32[] calldata proof
  ) public validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity >= sales[saleId].purchaseMinimum,
      "purchase below minimum"
    );

    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    require(paymentToken.allowance(msg.sender, address(this)) >= tokenQuantity, "allowance too low");

    // move the funds
    paymentToken.safeTransferFrom(msg.sender, sales[saleId].recipient, tokenQuantity);

    // effects after interaction: we need a reentrancy guard
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    emit Buy(saleId, msg.sender, tokenQuantity, false, proof);
  }

  // pay with the native token
  function buy(
    bytes32 saleId,
    bytes32[] calldata proof
  ) public payable validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // convert to the equivalent payment token value from wei
    uint256 tokenQuantity = nativeToPaymentToken(msg.value);
  
    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity >= sales[saleId].purchaseMinimum,
      "purchase below minimum"
    );

    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    // Forward eth to PullPayment escrow for withdrawal to recipient
    /**
     * @dev OZ PullPayment._asyncTransfer
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract,
     * so there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    _asyncTransfer(getRecipient(saleId), msg.value);

    // account for the purchase in equivalent payment token value
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    // flag this payment as using the native token
    emit Buy(saleId, msg.sender, tokenQuantity, true, proof);
  }

  // Tell users where they can claim tokens
  function registerClaimManager(bytes32 saleId, address claimManager) public validSale(saleId) isAdmin(saleId) {
    require(claimManager != address(0), "Claim manager must be a non-zero address");
    sales[saleId].claimManager = claimManager;
    emit RegisterClaimManager(saleId, claimManager);
  }

  function recoverERC20(bytes32 saleId, address tokenAddress, uint256 tokenAmount) public isAdmin(saleId) {
    IERC20(tokenAddress).transfer(getRecipient(saleId), tokenAmount);
  }
}