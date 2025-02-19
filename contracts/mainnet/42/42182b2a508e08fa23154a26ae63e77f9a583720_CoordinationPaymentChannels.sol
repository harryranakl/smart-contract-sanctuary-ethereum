// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./KRoles.sol";

contract CanReclaimTokens is KRoles {
    using SafeERC20 for IERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    function blacklistRecoverableToken(address _token) public onlyOperator {
        recoverableTokensBlacklist[_token] = true;
    }

    /// @notice Allow the owner of the contract to recover funds accidentally
    /// sent to the contract. To withdraw ETH, the token should be set to `0x0`.
    function recoverTokens(address _token) external onlyOperator {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        if (_token == address(0x0)) {
           (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(_token).safeTransfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./CanReclaimTokens.sol";

interface IWETH {
    function withdraw(uint wad) external;
}

contract CoordinationPaymentChannels is CanReclaimTokens {
    using SafeERC20 for IERC20;

    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes constant public INSTANT_WITHDRAWAL_COMMITMENT_DATA = bytes("INSTANT");

    // This keypair is responsible for signing stake commitments
    address public coordinator;
    // This keypair is responsible for signing user claim commitments
    address public claimGenerator;

    /* coordinator <-> keeper payment channels
     * The Coordinator and Keepers transact off-chain using these payment channels in a series of auctions
     * hosted by the Coordinator. The values stored in these variables reflect the latest on-chain state for a
     * payment channel, but the actual state of the payment channels is likely to be more recent than what is on
     * chain. The Coordinator and keeepers will pass signed commitments back and forth dictating what the current state
     * of the payment channel is.
     * A payment channel is keyed by a Keeper's stake address.
     * Note a keeper may have multiple payment channels / stake addresses.
     */
    // The amount of WETH a keeper's stake address has staked. This determines their maximum spending power.
    mapping (address => uint256) public stakedAmount;
    // This nonce is used to give an ordering to the off-chain stake commitments and to prevent replays on-chain.
    mapping (address => uint256) public stakeNonce;
    // The total amount of WETH a keeper has currently spent. Cannot be greater than stakedAmount.
    mapping (address => uint256) public stakeSpent;
    // Used to prevent channel reuse edge cases if a stake address closes their channel and opens another.
    mapping (address => uint256) public channelNonce;
    // Used to track the expiration of withdrawal timelocks.
    mapping (bytes32 => uint256) public withdrawalTimelockTimestamp;

    /* claim generator -> user payment channels
     * The Claim Generator will generate claims using the Keeper bids from the Coordinator auctions. Claim amounts are
     * calculated as a percentage of the bid amounts determined by the DAO. Given that bids are signed by Keepers and
     * the Claim Generator, and they are available publicly, claim amount correcntess is easily verifiable off-chain.
     *
     * userClaimedAmount tracks how much a user has claimed to date. A user's outstanding claim amount is given by
     * subtracting userClaimedAmount from their most recent claim commitment generated by the Claim Generator.
     */
    mapping (address => uint256) public userClaimedAmount;


    /* Total amount of claimable WETH. Accrues when commitments are submitted to `initiateTimelockedWithdrawal`,
     * `executeInstantWithdrawal`, and `settleSpentStake` and when `addClaimable` is called.
     */
    uint256 public totalClaimableAmount;

    event Staked(address indexed _stakeAddress, uint256 _channelNonce, uint256 _amount);
    event Claimed(address indexed _claimAddress, uint256 _amount);
    event CoordinatorChanged(address indexed _oldCoordinator, address indexed _newCoordinator);
    event ClaimGeneratorChanged(address indexed _oldClaimGenerator, address indexed _newClaimGenerator);
    event StakeWithdrawn(address indexed _stakeAddress, uint256 _channelNonce, uint256 _amount);
    event TimelockedWithdrawalInitiated(
        address indexed _stakeAddress, 
        uint256 _stakeSpent, 
        uint256 _stakeNonce, 
        uint256 _channelNonce, 
        uint256 _withdrawalTimelock);
    event AddedClaimable(uint256 _amount);
    event Settled(uint256 _refundedAmount, uint256 _accruedAmount);

    /* Represents a payment channel state. The Coordinator and Keepers will sign commitments to agree upon the current
     * Note, the `data` field is used off-chain to hold the hash of the previous commitment to ensure that the 
     * Coordinator and Keeper state for the payment channel is always consistent. The only time any assertions are made
     * on its value is `executeInstantWithdrawal` when it should equal `INSTANT_WITHDRAWAL_COMMITMENT_DATA`.
     */
    struct StakeCommitment {
        address stakeAddress;
        uint256 stakeSpent;
        uint256 stakeNonce;
        uint256 channelNonce;
        bytes data;
        bytes stakeAddressSignature;
        bytes coordinatorSignature;
    }

    /// @notice Retreives the payment channel state for the provided stake address.
    function getStakerState(
        address _stakeAddress
    ) public view returns (
        uint256 _stakedAmount, 
        uint256 _stakeNonce, 
        uint256 _stakeSpent, 
        uint256 _channelNonce, 
        uint256 _withdrawalTimelock
    ) {
        return (
            stakedAmount[_stakeAddress], 
            stakeNonce[_stakeAddress], 
            stakeSpent[_stakeAddress], 
            channelNonce[_stakeAddress], 
            getCurrentWithdrawalTimelock(_stakeAddress));
    }

    /** @notice Calculate the commitment hash used for signatures for a particular stake payment channel state.
      * @dev The Coordinator and Keepers transact off-chain by passing signed commitments back and forth. Signed stake 
      *      commitments are submitted on-chain only to perform settlements and withdrawals.
      */
    function stakeCommitmentHash(
        address _stakeAddress, 
        uint256 _stakeSpent, 
        uint256 _stakeNonce, 
        uint256 _channelNonce, 
        bytes memory _data
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_stakeAddress, _stakeSpent, _stakeNonce, _channelNonce, _data));
    }

    function stakeCommitmentHash(
        StakeCommitment memory _commitment
    ) internal pure returns (bytes32) {
        return stakeCommitmentHash(
            _commitment.stakeAddress, 
            _commitment.stakeSpent, 
            _commitment.stakeNonce, 
            _commitment.channelNonce, 
            _commitment.data);
    }

    /** @notice Calculate the commitment hash used for signatures for a particular claim payment channel state.
      *         Signed claim commitments are generated by the claim generator and used by users to perform claims.
      */
    function claimCommitmentHash(
        address _claimAddress, 
        uint256 _earningsToDate
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_claimAddress, _earningsToDate));
    }

    /** @notice Calculate the key to the entry in the withdrawalTimelockTimestamp map for a particular stake
      *         payment channel state.
      */
    function withdrawalTimelockKey(
        address _stakeAddress, 
        uint256 _stakeSpent, 
        uint256 _stakeNonce, 
        uint256 _channelNonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_stakeAddress, _stakeSpent, _stakeNonce, _channelNonce));
    }

    /** @notice Get the withdrawal timelock expiration for a payment channel. A return value of 0 indicates no timelock.
      * @dev The withdrawal timelock allows the Coordinator to withdrawals with newer commitments.
      */
    function getCurrentWithdrawalTimelock(
        address _stakeAddress
    ) public view returns (uint256) {
        return withdrawalTimelockTimestamp[
            withdrawalTimelockKey(
                _stakeAddress, 
                stakeSpent[_stakeAddress], 
                stakeNonce[_stakeAddress], 
                channelNonce[_stakeAddress])];
    }

    constructor(address _coordinator, address _claimGenerator) {
        coordinator = _coordinator;
        claimGenerator = _claimGenerator;
        blacklistRecoverableToken(address(WETH));
        emit CoordinatorChanged(address(0), _coordinator);
        emit ClaimGeneratorChanged(address(0), _claimGenerator);
    }

    fallback() external payable {}

    receive() external payable {}

    /** @notice Update the Coordinator address. This keypair is responsible for signing stake commitments.
      * @dev To migrate Coordinator addresses, any commitments signed by the old Coordinator must be resigned by the
      *      new Coordinator address.
      */ 
    function updateCoordinatorAddress(
        address _newCoordinator
    ) external onlyOperator {
        emit CoordinatorChanged(coordinator, _newCoordinator);
        coordinator = _newCoordinator;
    }

    /** @notice Update the claimGenerator address. This keypair is responsible to for signing user claim commitments.
      * @dev To migrate claimGenerator addresses, any commitments signed by the old Claim address must be resigned by
      *      the new claimGenerator address.
      */
    function updateClaimGeneratorAddress(
        address _newClaimGenerator
    ) external onlyOperator {
        emit ClaimGeneratorChanged(claimGenerator, _newClaimGenerator);
        claimGenerator = _newClaimGenerator;
    }

    /** @notice Add WETH to the payment channel of msg.sender. Cannot be done while in a timelocked withdrawal.
      * @dev Withdrawal of stake will require a signature from the Coordinator.
      */
    function stake(
        uint256 _amount
    ) public {
        require(getCurrentWithdrawalTimelock(msg.sender) == 0, "cannot stake while in withdrawal");
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        stakedAmount[msg.sender] += _amount;
        emit Staked(msg.sender, channelNonce[msg.sender], stakedAmount[msg.sender]);
    }

    /** @notice Used to add claimable WETH to the contract.
      * @dev Since claimable WETH otherwise only accrues on withdrawal or settlement of WETH, this can be used create a
      *      buffer of immediately claimable WETH so users do not need to wait for a Keeper to withdraw or for someone
      *      to call the `settleSpentStake` function. This can also be used to amend deficits from overgenerous claims.
      */
    function addClaimable(
        uint256 _amount
    ) public {
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        totalClaimableAmount += _amount;
        emit AddedClaimable(_amount);
    }

    /** @dev The stakeSpent for a payment channel will increase when a stake address makes payments and decrease
      *      when the Coordinator issues refunds. This function changes the totalClaimableAmount of WETH on the contract
      *      accordingly.
      */
    function adjustTotalClaimableAmountByStakeSpentChange(
        uint256 _oldStakeSpent, 
        uint256 _newStakeSpent
    ) internal {
        if (_newStakeSpent < _oldStakeSpent) {
            // If a stake address's new stakeSpent is less than their previously stored stakeSpent, then a refund was 
            // issued to the stakeAddress. We "refund" this WETH to the stakeAddress by subtracting 
            // the difference from totalClaimableAmount.
            uint256 refundAmount = _oldStakeSpent - _newStakeSpent;
            require(totalClaimableAmount >= refundAmount, "not enough claimable WETH to refund");
            totalClaimableAmount -= refundAmount;
        } else {
            // Otherwise we accrue any unsettled spent stake to totalClaimableAmount.
            totalClaimableAmount += _newStakeSpent - _oldStakeSpent;
        }
    }

    /** @notice Used to settle spent stake for a payment channel to accrue claimable WETH. 
      * @dev Note anyone can call this function since it requires a signature from both keepers and the coordinator.
      *      It will primarily be used by the coordinator but a user who would like to claim WETH immediately when there
      *      is no claimable WETH may also call this to accrue claimable WETH.
      * @param _commitments is a list of StakeCommitments. There should be one entry for each payment channel being
      *        settled and it should be the latest commitment for that channel. We only care about the most recent
      *        state for a payment channel, so evenif there are multiple commitments for a payment channel that have not
      *        been submitted on-chain, only the latest needs to be submitted. The resulting contract state will be the
      *        same regardless.
      */
    function settleSpentStake(
        StakeCommitment[] memory _commitments
    ) external {
        uint256 claimableWETHToAccrue = 0;
        uint256 claimableWETHToRefund = 0;
        for (uint i=0; i< _commitments.length; i++) {
            StakeCommitment memory commitment = _commitments[i];
            // Initiating withdrawal settles the spent stake in the payment channel. Thus we disable settling spent
            // stake using this function for a payment channel in withdrawal. Proper settlement of the payment channel
            // should be handled by the withdrawal process.
            require(getCurrentWithdrawalTimelock(commitment.stakeAddress) == 0, "cannot settle while in withdrawal");
            require(commitment.stakeSpent <= stakedAmount[commitment.stakeAddress], "cannot spend more than is staked");
            require(commitment.stakeNonce > stakeNonce[commitment.stakeAddress], "stake nonce is too old");
            require(commitment.channelNonce == channelNonce[commitment.stakeAddress], "incorrect channel nonce");

            address recoveredStakeAddress = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(stakeCommitmentHash(commitment)), 
                commitment.stakeAddressSignature);
            require(recoveredStakeAddress == commitment.stakeAddress, "recovered address is not the stake address");
            address recoveredCoordinatorAddress =  ECDSA.recover(
                ECDSA.toEthSignedMessageHash(stakeCommitmentHash(commitment)), 
                commitment.coordinatorSignature);
            require(recoveredCoordinatorAddress == coordinator, "recovered address is not the coordinator");

            if (commitment.stakeSpent < stakeSpent[commitment.stakeAddress]) {
                // If a stake address's new stakeSpent is less than their previously stored stakeSpent, then a refund was 
                // issued to the stakeAddress. We "refund" this WETH to the stakeAddress by subtracting 
                // the difference from totalClaimableAmount.
                claimableWETHToRefund += stakeSpent[commitment.stakeAddress] - commitment.stakeSpent;
            } else {
                // Otherwise we accrue any unsettled spent stake to totalClaimableAmount
                claimableWETHToAccrue += commitment.stakeSpent - stakeSpent[commitment.stakeAddress];
            }
            stakeNonce[commitment.stakeAddress] = commitment.stakeNonce;
            stakeSpent[commitment.stakeAddress] = commitment.stakeSpent;
        }
        adjustTotalClaimableAmountByStakeSpentChange(claimableWETHToRefund, claimableWETHToAccrue);
        emit Settled(claimableWETHToRefund, claimableWETHToAccrue);
    }

    /** @notice Initiate or challenge withdrawal, which can be completed after a 7 day timelock expires.
      * @dev Used by the stake addresses to withdraw from and close the payment channel. Also used by the Coordinator to
      *      challenge a withdrawal. The most recent commitment for the payment channel that has been signed by both the
      *      stake address and the Coordinator should be used for the withdrawal. In order to prevent Keepers from
      *      immediately exiting with an old commitment, potentially taking WETH they do not own, there is a 7 day
      *      timelock on being able to complete the withdrawal. If the Coordinator has a more recent commitment, they
      *      will submit it to this function resetting the timelock.
      */
    function initiateTimelockedWithdrawal(
        StakeCommitment memory _commitment
    ) external {
        // This is to prevent people who are not the payment channel owner from initiating the withdrawal process.
        if (getCurrentWithdrawalTimelock(_commitment.stakeAddress) == 0) {
            require(msg.sender == _commitment.stakeAddress, "only stakeAddress can start the withdrawal process");
        }
        require(_commitment.stakeSpent <= stakedAmount[_commitment.stakeAddress], "cannot spend more than is staked");
        // The stakeNonce may have been seen in settleSpentStake so we must allow >= to here.
        // Note this means a malicious or compromised Coordinator has the ability to indefinitely reset the timelock.
        // This is fine since we can just change the Coordinator address.
        require(_commitment.stakeNonce >= stakeNonce[_commitment.stakeAddress], "stake nonce is too old");
        require(_commitment.channelNonce == channelNonce[_commitment.stakeAddress], "incorrect channel nonce");
        require(msg.sender == _commitment.stakeAddress || msg.sender == coordinator, 
            "only callable by stakeAdddress or coordinator");
        
        address recoveredStakeAddress = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(stakeCommitmentHash(_commitment)), 
            _commitment.stakeAddressSignature);
        require(recoveredStakeAddress == _commitment.stakeAddress, "recovered address is not the stake address");
        address recoveredCoordinatorAddress =  ECDSA.recover(
            ECDSA.toEthSignedMessageHash(stakeCommitmentHash(_commitment)), 
            _commitment.coordinatorSignature);
        require(recoveredCoordinatorAddress == coordinator, "recovered address is not the coordinator");

        adjustTotalClaimableAmountByStakeSpentChange(stakeSpent[_commitment.stakeAddress], _commitment.stakeSpent);
        stakeNonce[_commitment.stakeAddress] = _commitment.stakeNonce;
        stakeSpent[_commitment.stakeAddress] = _commitment.stakeSpent;

        // Initiate the timelock
        withdrawalTimelockTimestamp[
            withdrawalTimelockKey(
                _commitment.stakeAddress, 
                _commitment.stakeSpent, 
                _commitment.stakeNonce, 
                _commitment.channelNonce
            )] = block.timestamp + 7 days;

        emit TimelockedWithdrawalInitiated(
            _commitment.stakeAddress, 
            _commitment.stakeSpent, 
            _commitment.stakeNonce, 
            _commitment.channelNonce, 
            block.timestamp + 7 days);
    }

    /** @notice Withdraw remaining stake from the payment channel after the withdrawal timelock has concluded.
      * @dev Closing the payment channel zeros out all payment channel state for the stake address aside from the
      *      channelNonce which is incremented. This is to prevent any channel reuse edge cases. A stake address that
      *      has closed their payment channel and withdrawn is able to create a new payment channel by staking WETH. 
      */
    function executeTimelockedWithdrawal(
        address _stakeAddress
    ) public {
        uint256 _channelNonce = channelNonce[_stakeAddress];
        require(getCurrentWithdrawalTimelock(_stakeAddress) > 0, "must initiate timelocked withdrawal first");
        require(block.timestamp > getCurrentWithdrawalTimelock(_stakeAddress), "still in withdrawal timelock");
        
        uint256 withdrawalAmount = stakedAmount[_stakeAddress] - stakeSpent[_stakeAddress];
        stakeNonce[_stakeAddress] = 0;
        stakeSpent[_stakeAddress] = 0;
        stakedAmount[_stakeAddress] = 0;
        channelNonce[_stakeAddress] += 1;

        WETH.safeTransfer(_stakeAddress, withdrawalAmount);

        emit StakeWithdrawn(_stakeAddress, _channelNonce, withdrawalAmount);
    }

    /** @notice Instantly withdraw remaining stake in payment channel.
      * @dev To perform an instant withdrawal a Keeper will ask the coordinator for an instant withdrawal signature. 
      *      This `data` field in the commitment used to produce the signature should be populated with 
      *      `INSTANT_WITHDRAWAL_COMMITMENT_DATA`. We don't want a compromised Coordinator to instantly settle the 
      *      channel with an old commitment, so we also require a stakeAddress instant withdrawal signature.
      *      Closing the payment channel zeros out all payment channel state for the stake address aside from the
      *      channelNonce which is incremented. This is to prevent any channel reuse edge cases. A stake address that
      *      has closed their payment channel and withdrawn is able to create a new payment channel by staking WETH.
      */
    function executeInstantWithdrawal(
        StakeCommitment memory _commitment
    ) external {
        require(msg.sender == _commitment.stakeAddress, "only stakeAddress can perform instant withdrawal");
        require(_commitment.stakeSpent <= stakedAmount[_commitment.stakeAddress], "cannot spend more than is staked");
        // The stakeNonce may have been seen in settleSpentStake so we must allow >= to here.
        // Note this means a malicious or compromised Coordinator has the ability to indefinitely reset the timelock.
        // This is fine since we can just change the Coordinator address.
        require(_commitment.stakeNonce >= stakeNonce[_commitment.stakeAddress], "stake nonce is too old");
        require(_commitment.channelNonce == channelNonce[_commitment.stakeAddress], "incorrect channel nonce");
        require(keccak256(_commitment.data) == keccak256(INSTANT_WITHDRAWAL_COMMITMENT_DATA), "incorrect data payload");

        address recoveredStakeAddress =  ECDSA.recover(
            ECDSA.toEthSignedMessageHash(stakeCommitmentHash(_commitment)),
            _commitment.stakeAddressSignature);
        require(recoveredStakeAddress == _commitment.stakeAddress, "recovered address is not the stake address");
        address recoveredCoordinatorAddress =  ECDSA.recover(
            ECDSA.toEthSignedMessageHash(stakeCommitmentHash(_commitment)),
            _commitment.coordinatorSignature);
        require(recoveredCoordinatorAddress == coordinator, "recovered address is not the coordinator");

        adjustTotalClaimableAmountByStakeSpentChange(stakeSpent[_commitment.stakeAddress], _commitment.stakeSpent);
        uint256 withdrawalAmount = stakedAmount[_commitment.stakeAddress] - _commitment.stakeSpent;
        stakeNonce[_commitment.stakeAddress] = 0;
        stakeSpent[_commitment.stakeAddress] = 0;
        stakedAmount[_commitment.stakeAddress] = 0;
        channelNonce[_commitment.stakeAddress] += 1;

        WETH.safeTransfer(_commitment.stakeAddress, withdrawalAmount);

        emit StakeWithdrawn(_commitment.stakeAddress, _commitment.channelNonce, withdrawalAmount);
    }


    /** @notice Claim accumulated earnings. Claim amounts are determined off-chain and signed by the claimGenerator
      *         address. Claim amounts are calculated as a pre-determined percentage of a Keeper's bid, and Keeper bids
      *         are signed by both Keepers and the Coordinator, so claim amount correctness is easily verifiable
      *         off-chain by consumers even if it is not verified on-chain.
      * @dev Note that it is not feasible to verify claim amount correctness on-chain as the total claim amount for
      *      a user can be the sum of claims generated from any number of bid commitments. Claimers only rely on the
      *      claim generator to calculate the claim as a percentage of Keeper bids correctly and this is easily
      *      verifiable by consumers off-chain given the signed bid commitments are public.
      *      A user has claimable WETH if the Claim Generator has generated a commitment for them where `earningsToDate`
      *      is greater than `userClaimedAmount[_claimAddress]`.
      */
    function claim(
        address _claimAddress,
        uint256 _earningsToDate,
        bytes memory _claimGeneratorSignature
    ) external {
        processClaim(
            _claimAddress,
            _earningsToDate,
            _claimGeneratorSignature,
            false
        );
    }

    /** @notice Claim accumulated earnings, and unwrap to ETH. Claim amounts are determined off-chain and signed by the claimGenerator
      *         address. Claim amounts are calculated as a pre-determined percentage of a Keeper's bid, and Keeper bids
      *         are signed by both Keepers and the Coordinator, so claim amount correctness is easily verifiable
      *         off-chain by consumers even if it is not verified on-chain.
      * @dev Note that it is not feasible to verify claim amount correctness on-chain as the total claim amount for
      *      a user can be the sum of claims generated from any number of bid commitments. Claimers only rely on the
      *      claim generator to calculate the claim as a percentage of Keeper bids correctly and this is easily
      *      verifiable by consumers off-chain given the signed bid commitments are public.
      *      A user has claimable WETH if the Claim Generator has generated a commitment for them where `earningsToDate`
      *      is greater than `userClaimedAmount[_claimAddress]`.
      */
    function claimAndUnwrap(
        address _claimAddress,
        uint256 _earningsToDate,
        bytes memory _claimGeneratorSignature
    ) external {
        processClaim(
            _claimAddress,
            _earningsToDate,
            _claimGeneratorSignature,
            true
        );
    }

    /** @notice Claim accumulated earnings. Claim amounts are determined off-chain and signed by the claimGenerator
      *         address. Claim amounts are calculated as a pre-determined percentage of a Keeper's bid, and Keeper bids
      *         are signed by both Keepers and the Coordinator, so claim amount correctness is easily verifiable
      *         off-chain by consumers even if it is not verified on-chain.
      * @dev Note that it is not feasible to verify claim amount correctness on-chain as the total claim amount for
      *      a user can be the sum of claims generated from any number of bid commitments. Claimers only rely on the
      *      claim generator to calculate the claim as a percentage of Keeper bids correctly and this is easily
      *      verifiable by consumers off-chain given the signed bid commitments are public.
      *      A user has claimable WETH if the Claim Generator has generated a commitment for them where `earningsToDate`
      *      is greater than `userClaimedAmount[_claimAddress]`.
      */
    function processClaim(
        address _claimAddress,
        uint256 _earningsToDate,
        bytes memory _claimGeneratorSignature,
        bool unwrap
    ) internal {
        require(_earningsToDate > userClaimedAmount[_claimAddress], "nothing to claim");

        // Validate the signature
        address recoveredClaimGeneratorAddress = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(claimCommitmentHash(_claimAddress, _earningsToDate)),
            _claimGeneratorSignature);
        require(recoveredClaimGeneratorAddress == claimGenerator, "recoveredClaimGeneratorAddress is not the account manager");

        // Calculate the claimAmount
        uint256 claimAmount = _earningsToDate - userClaimedAmount[_claimAddress];
        require(claimAmount <= totalClaimableAmount, "claim amount exceeds balance on contract");
        userClaimedAmount[_claimAddress] = _earningsToDate;
        totalClaimableAmount -= claimAmount;

        // Transfer the earnings to _claimAddress
        if (unwrap) {
            IWETH(address(WETH)).withdraw(claimAmount);
            (bool sent, bytes memory data) = _claimAddress.call{value: claimAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            WETH.safeTransfer(_claimAddress, claimAmount);
        }

        emit Claimed(_claimAddress, claimAmount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract KRoles is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    constructor() {
        /// Note, given that it is possible for both the DEFAULT_ADMIN_ROLE and OPERATOR_ROLE to renounce their roles,
        /// the contract can reach a state where there are not operators or admins. Users of inherting contracts should
        /// be sure to avoid reaching this state, as they will be permanently locked out of using any functions relying
        /// on the `onlyOperator` modifier for access control.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        _setRoleAdmin (OPERATOR_ROLE, DEFAULT_ADMIN_ROLE) ;
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addOperator(address account) public {
        _addOperator(account);
    }

    /** @notice Renounces operator role of msg.sender. Note that it is possible for all operators to be renounced, which
      * will lock functions relying on the `onlyOperator` modifier for access control.
      */
    function renounceOperator() public virtual {
        _renounceOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        grantRole(OPERATOR_ROLE, account);
        emit OperatorAdded(account);
    }

    function _renounceOperator(address account) internal {
        renounceRole(OPERATOR_ROLE, account);
        emit OperatorRemoved(account);
    }
}