// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

import "../ERC20GuildUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/*
  @title DXDGuild
  @author github:AugustoL
  @dev An ERC20GuildUpgradeable for the DXD token designed to execute votes on Genesis Protocol Voting Machine.
*/
contract DXDGuild is ERC20GuildUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // @dev Initilizer
    // @param _token The ERC20 token that will be used as source of voting power
    // @param _proposalTime The amount of time in seconds that a proposal will be active for voting
    // @param _timeForExecution The amount of time in seconds that a proposal action will have to execute successfully
    // @param _votingPowerPercentageForProposalExecution The percentage of voting power in base 10000 needed to execute a proposal
    // action
    // @param _votingPowerPercentageForProposalCreation The percentage of voting power in base 10000 needed to create a proposal
    // @param _voteGas The amount of gas in wei unit used for vote refunds
    // @param _maxGasPrice The maximum gas price used for vote refunds
    // @param _maxActiveProposals The maximum amount of proposals to be active at the same time
    // @param _lockTime The minimum amount of seconds that the tokens would be locked
    // @param _permissionRegistry The address of the permission registry contract to be used
    // @param _votingMachine The voting machine where the guild will vote
    function initialize(
        address _token,
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votingPowerPercentageForProposalExecution,
        uint256 _votingPowerPercentageForProposalCreation,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _maxActiveProposals,
        uint256 _lockTime,
        address _permissionRegistry,
        address _votingMachine
    ) public initializer {
        __Ownable_init();
        super.initialize(
            _token,
            _proposalTime,
            _timeForExecution,
            _votingPowerPercentageForProposalExecution,
            _votingPowerPercentageForProposalCreation,
            "DXDGuild",
            _voteGas,
            _maxGasPrice,
            _maxActiveProposals,
            _lockTime,
            _permissionRegistry
        );
        permissionRegistry.setETHPermission(
            address(this),
            _votingMachine,
            bytes4(keccak256("vote(bytes32,uint256,uint256,address)")),
            0,
            true
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../utils/PermissionRegistry.sol";
import "../utils/TokenVault.sol";
import "./BaseERC20Guild.sol";

/*
  @title ERC20GuildUpgradeable
  @author github:AugustoL
  @dev Extends an ERC20 functionality into a Guild, adding a simple governance system over an ERC20 token.
  An ERC20Guild is a simple organization that execute arbitrary calls if a minimum amount of votes is reached in a 
  proposal option while the proposal is active.
  The token used for voting needs to be locked for a minimum period of time in order to be used as voting power.
  Every time tokens are locked the timestamp of the lock is updated and increased the lock time seconds.
  Once the lock time passed the voter can withdraw his tokens.
  Each proposal has options, the voter can vote only once per proposal and cant change the chosen option, only
  increase the voting power of his vote.
  A proposal ends when the minimum amount of total voting power is reached on a proposal option before the proposal
  finish.
  When a proposal ends successfully it executes the calls of the winning option.
  The winning option has a certain amount of time to be executed successfully if that time passes and the option didn't
  executed successfully, it is marked as failed.
  The guild can execute only allowed functions, if a function is not allowed it will need to set the allowance for it.
  The allowed functions have a timestamp that marks from what time the function can be executed.
  A limit to a maximum amount of active proposals can be set, an active proposal is a proposal that is in Active state.
  Gas can be refunded to the account executing the vote, for this to happen the voteGas and maxGasPrice values need to
  be set.
  Signed votes can be executed in behalf of other users, to sign a vote the voter needs to hash it with the function
  hashVote, after signing the hash teh voter can share it to other account to be executed.
  Multiple votes and signed votes can be executed in one transaction.
*/
contract ERC20GuildUpgradeable is BaseERC20Guild, Initializable {
    // @dev Initializer
    // @param _token The ERC20 token that will be used as source of voting power
    // @param _proposalTime The amount of time in seconds that a proposal will be active for voting
    // @param _timeForExecution The amount of time in seconds that a proposal option will have to execute successfully
    // @param _votingPowerPercentageForProposalExecution The percentage of voting power in base 10000 needed to execute a proposal
    // action
    // @param _votingPowerPercentageForProposalCreation The percentage of voting power in base 10000 needed to create a proposal
    // @param _name The name of the ERC20Guild
    // @param _voteGas The amount of gas in wei unit used for vote refunds
    // @param _maxGasPrice The maximum gas price used for vote refunds
    // @param _maxActiveProposals The maximum amount of proposals to be active at the same time
    // @param _lockTime The minimum amount of seconds that the tokens would be locked
    // @param _permissionRegistry The address of the permission registry contract to be used
    function initialize(
        address _token,
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votingPowerPercentageForProposalExecution,
        uint256 _votingPowerPercentageForProposalCreation,
        string memory _name,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _maxActiveProposals,
        uint256 _lockTime,
        address _permissionRegistry
    ) public virtual initializer {
        require(address(_token) != address(0), "ERC20Guild: token cant be zero address");
        require(_proposalTime > 0, "ERC20Guild: proposal time has to be more than 0");
        require(_lockTime >= _proposalTime, "ERC20Guild: lockTime has to be higher or equal to proposalTime");
        require(
            _votingPowerPercentageForProposalExecution > 0,
            "ERC20Guild: voting power for execution has to be more than 0"
        );
        name = _name;
        token = IERC20Upgradeable(_token);
        tokenVault = new TokenVault(address(token), address(this));
        proposalTime = _proposalTime;
        timeForExecution = _timeForExecution;
        votingPowerPercentageForProposalExecution = _votingPowerPercentageForProposalExecution;
        votingPowerPercentageForProposalCreation = _votingPowerPercentageForProposalCreation;
        voteGas = _voteGas;
        maxGasPrice = _maxGasPrice;
        maxActiveProposals = _maxActiveProposals;
        lockTime = _lockTime;
        permissionRegistry = PermissionRegistry(_permissionRegistry);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PermissionRegistry.
 * @dev A registry of smart contracts functions and ERC20 transfer limits that are allowed to be called between contracts.
 * A time delay in seconds over the permissions can be set form any contract, this delay would be added to any new
 * permissions sent by that address.
 * The PermissionRegistry owner (if there is an owner and owner address is not 0x0) can overwrite/set any permission.
 * The registry allows setting ERC20 limits, the limit needs to be set at the beggining of the block and then it can be
 * checked at any time. To remove or replace ERC20 limits first it needs to be removed and then it can be set again.
 * The smart contracts permissions are compound by the `from` address, `to` address, `value` uint256 and `fromTime` uint256,
 * if `fromTime` is zero it means the function is not allowed.
 */

contract PermissionRegistry is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) public permissionDelay;

    event PermissionSet(address from, address to, bytes4 functionSignature, uint256 fromTime, uint256 value);

    struct ETHPermission {
        uint256 valueTransferred;
        uint256 valueTransferedOnBlock;
        uint256 valueAllowed;
        uint256 fromTime;
    }

    struct ERC20Limit {
        address token;
        uint256 initialValueOnBlock;
        uint256 valueAllowed;
        uint256 removeTime;
    }

    // from address => to address => function call signature allowed => Permission
    mapping(address => mapping(address => mapping(bytes4 => ETHPermission))) public ethPermissions;

    // from address => array of tokens allowed and the max value ot be transferred per block
    mapping(address => ERC20Limit[]) erc20Limits;

    // mapping of the last block number used for the initial balance
    mapping(address => uint256) erc20LimitsOnBlock;

    /**
     * @dev initializer
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Set the time delay for a call to show as allowed
     * @param _timeDelay The amount of time that has to pass after permission addition to allow execution
     */
    function setETHPermissionDelay(address from, uint256 _timeDelay) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        permissionDelay[from] = _timeDelay;
    }

    /**
     * @dev Sets the time from which the function can be executed from a contract to another a with which value.
     * @param from The address that will execute the call
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     * @param valueAllowed The amount of value allowed of the token to be sent
     * @param allowed If the function is allowed or not.
     */
    function setETHPermission(
        address from,
        address to,
        bytes4 functionSignature,
        uint256 valueAllowed,
        bool allowed
    ) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(to != address(this), "PermissionRegistry: Cant set ethPermissions to PermissionRegistry");
        if (allowed) {
            ethPermissions[from][to][functionSignature].fromTime = block.timestamp.add(permissionDelay[from]);
            ethPermissions[from][to][functionSignature].valueAllowed = valueAllowed;
        } else {
            ethPermissions[from][to][functionSignature].fromTime = 0;
            ethPermissions[from][to][functionSignature].valueAllowed = 0;
        }
        emit PermissionSet(
            from,
            to,
            functionSignature,
            ethPermissions[from][to][functionSignature].fromTime,
            ethPermissions[from][to][functionSignature].valueAllowed
        );
    }

    /**
     * @dev Add an ERC20Limit for an address, there cannot be more than one limit per token.
     * @param from The address that will execute the call
     * @param token The erc20 token to set the limit
     * @param valueAllowed The amount of value allowed of the token to be sent
     * @param index The index of the token permission in the erco limits
     */
    function addERC20Limit(
        address from,
        address token,
        uint256 valueAllowed,
        uint256 index
    ) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(index <= erc20Limits[from].length, "PermissionRegistry: Index out of bounds");
        require(token != address(0), "PermissionRegistry: Token address cannot be 0x0");

        uint256 balanceNow = IERC20(token).balanceOf(msg.sender);

        // set 0 as initialvalue to not allow any balance change for this token on this block
        if (index == erc20Limits[from].length) {
            for (uint256 i = 0; i < erc20Limits[from].length; i++) {
                require(erc20Limits[from][i].token != token, "PermissionRegistry: Limit on token already added");
            }
            erc20Limits[from].push(ERC20Limit(token, balanceNow, valueAllowed, 0));
        } else {
            require(
                erc20Limits[from][index].token == address(0),
                "PermissionRegistry: Cant override existent ERC20 limit"
            );
            erc20Limits[from][index].token = token;
            erc20Limits[from][index].initialValueOnBlock = balanceNow;
            erc20Limits[from][index].valueAllowed = valueAllowed;
            erc20Limits[from][index].removeTime = 0;
        }
    }

    /**
     * @dev Removes an ERC20 limit of an address by its index in the ERC20Lmits array.
     * (take in count that the limit execution has to be called after the remove time)
     * @param from The address that will execute the call
     * @param index The index of the token permission in the erco limits
     */
    function removeERC20Limit(address from, uint256 index) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(index < erc20Limits[from].length, "PermissionRegistry: Index out of bounds");

        erc20Limits[from][index].removeTime = block.timestamp.add(permissionDelay[from]);
    }

    /**
     * @dev Executes the final removal of an ERC20 limit of an address by its index in the ERC20Lmits array.
     * @param from The address that will execute the call
     * @param index The index of the token permission in the erco limits
     */
    function executeRemoveERC20Limit(address from, uint256 index) public {
        require(
            block.timestamp < erc20Limits[from][index].removeTime,
            "PermissionRegistry: Cant execute permission removal"
        );

        erc20Limits[from][index] = ERC20Limit(address(0), 0, 0, 0);
    }

    /**
     * @dev Sets the value transferred in a permission on the actual block and checks the allowed timestamp.
     *      It also checks that the value does not go over the permission other global limits.
     * @param from The address from which the call will be executed
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     * @param valueTransferred The value to be transferred
     */
    function setETHPermissionUsed(
        address from,
        address to,
        bytes4 functionSignature,
        uint256 valueTransferred
    ) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        if (valueTransferred > 0) {
            _setValueTransferred(ethPermissions[from][address(0)][bytes4(0)], valueTransferred);
        }

        (, uint256 fromTime) = getETHPermission(from, to, functionSignature);

        if (fromTime > 0) {
            require(fromTime < block.timestamp, "PermissionRegistry: Call not allowed yet");
            _setValueTransferred(ethPermissions[from][to][functionSignature], valueTransferred);
        } else if (functionSignature != bytes4(0)) {
            revert("PermissionRegistry: Call not allowed");
        }
    }

    /**
     * @dev Sets the value transferred in a a permission on the actual block.
     * @param permission The permission to add the value transferred
     * @param valueTransferred The value to be transferred
     */
    function _setValueTransferred(ETHPermission storage permission, uint256 valueTransferred) internal {
        if (permission.valueTransferedOnBlock < block.number) {
            permission.valueTransferedOnBlock = block.number;
            permission.valueTransferred = valueTransferred;
        } else {
            permission.valueTransferred = permission.valueTransferred.add(valueTransferred);
        }
        require(permission.valueTransferred <= permission.valueAllowed, "PermissionRegistry: Value limit reached");
    }

    /**
     * @dev Sets the initial balances for ERC20 tokens in the current block
     */
    function setERC20Balances() public {
        if (erc20LimitsOnBlock[msg.sender] < block.number) {
            erc20LimitsOnBlock[msg.sender] = block.number;
            for (uint256 i = 0; i < erc20Limits[msg.sender].length; i++) {
                erc20Limits[msg.sender][i].initialValueOnBlock = IERC20(erc20Limits[msg.sender][i].token).balanceOf(
                    msg.sender
                );
            }
        }
    }

    /**
     * @dev Checks the value transferred in block for all registered ERC20 limits.
     * @param from The address from which ERC20 tokens limits will be checked
     */
    function checkERC20Limits(address from) public returns (bool) {
        require(erc20LimitsOnBlock[from] == block.number, "PermissionRegistry: ERC20 initialValues not set");
        for (uint256 i = 0; i < erc20Limits[from].length; i++) {
            require(
                erc20Limits[from][i].initialValueOnBlock.sub(IERC20(erc20Limits[from][i].token).balanceOf(from)) <=
                    erc20Limits[from][i].valueAllowed,
                "PermissionRegistry: Value limit reached"
            );
        }
        return true;
    }

    /**
     * @dev Get the time delay to be used for an address
     * @param from The address to get the permission delay from
     */
    function getETHPermissionDelay(address from) public view returns (uint256) {
        return permissionDelay[from];
    }

    /**
     * @dev Gets the time from which the function can be executed from a contract to another and with which value.
     * In case of now being allowed to do the call it returns zero in both values
     * @param from The address from which the call will be executed
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     */
    function getETHPermission(
        address from,
        address to,
        bytes4 functionSignature
    ) public view returns (uint256 valueAllowed, uint256 fromTime) {
        // Allow by default internal contract calls and to this contract but with no value
        if ((from == to) || (to == address(this))) {
            return (0, 1);
        } else {
            return (
                ethPermissions[from][to][functionSignature].valueAllowed,
                ethPermissions[from][to][functionSignature].fromTime
            );
        }
    }

    /**
     * @dev Gets the vallue allowed to be sent in a block of the ER20 token
     * @param from The address from which the call will be executed
     * @param token The address that will be called
     */
    function getERC20Limit(address from, address token) public view returns (uint256) {
        for (uint256 i = 0; i < erc20Limits[from].length; i++)
            if (erc20Limits[from][i].token == token) return erc20Limits[from][i].valueAllowed;
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title TokenVault
 * @dev A smart contract to lock an ERC20 token in behalf of user trough an intermediary admin contract.
 * User -> Admin Contract -> Token Vault Contract -> Admin Contract -> User.
 * Tokens can be deposited and withdrawal only with authorization of the locker account from the admin address.
 */
contract TokenVault {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public token;
    address public admin;
    mapping(address => uint256) public balances;

    // @dev Initializer
    // @param _token The address of the token to be used
    // @param _admin The address of the contract that will execute deposits and withdrawals
    constructor(address _token, address _admin) {
        token = IERC20Upgradeable(_token);
        admin = _admin;
    }

    // @dev Deposit the tokens from the user to the vault from the admin contract
    function deposit(address user, uint256 amount) external {
        require(msg.sender == admin, "TokenVault: Deposit must be sent through admin");
        token.safeTransferFrom(user, address(this), amount);
        balances[user] = balances[user].add(amount);
    }

    // @dev Withdraw the tokens to the user from the vault from the admin contract
    function withdraw(address user, uint256 amount) external {
        require(msg.sender == admin);
        token.safeTransfer(user, amount);
        balances[user] = balances[user].sub(amount);
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function getAdmin() external view returns (address) {
        return admin;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../utils/PermissionRegistry.sol";
import "../utils/TokenVault.sol";

/*
  @title BaseERC20Guild
  @author github:AugustoL
  @dev Extends an ERC20 functionality into a Guild, adding a simple governance system over an ERC20 token.
  An ERC20Guild is a simple organization that execute arbitrary calls if a minimum amount of votes is reached in a 
  proposal option while the proposal is active.
  The token used for voting needs to be locked for a minimum period of time in order to be used as voting power.
  Every time tokens are locked the timestamp of the lock is updated and increased the lock time seconds.
  Once the lock time passed the voter can withdraw his tokens.
  Each proposal has options, the voter can vote only once per proposal and cannot change the chosen option, only
  increase the voting power of his vote.
  A proposal ends when the minimum amount of total voting power is reached on a proposal option before the proposal
  finish.
  When a proposal ends successfully it executes the calls of the winning option.
  The winning option has a certain amount of time to be executed successfully if that time passes and the option didn't
  executed successfully, it is marked as failed.
  The guild can execute only allowed functions, if a function is not allowed it will need to set the allowance for it.
  The allowed functions have a timestamp that marks from what time the function can be executed.
  A limit to a maximum amount of active proposals can be set, an active proposal is a proposal that is in Active state.
  Gas can be refunded to the account executing the vote, for this to happen the voteGas and maxGasPrice values need to
  be set.
  Signed votes can be executed in behalf of other users, to sign a vote the voter needs to hash it with the function
  hashVote, after signing the hash teh voter can share it to other account to be executed.
  Multiple votes and signed votes can be executed in one transaction.
  The guild can sign EIP1271 messages, to do this the guild needs to call itself and allow the signature to be verified 
  with and extra signature of any account with voting power.
*/
contract BaseERC20Guild {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;

    // This configuration value is defined as constant to be protected against a malicious proposal
    // changing it.
    uint8 public constant MAX_OPTIONS_PER_PROPOSAL = 10;

    enum ProposalState {
        None,
        Active,
        Rejected,
        Executed,
        Failed
    }

    // The ERC20 token that will be used as source of voting power
    IERC20Upgradeable public token;

    // The address of the PermissionRegistry to be used
    PermissionRegistry permissionRegistry;

    // The name of the ERC20Guild
    string public name;

    // The amount of time in seconds that a proposal will be active for voting
    uint256 public proposalTime;

    // The amount of time in seconds that a proposal option will have to execute successfully
    uint256 public timeForExecution;

    // The percentage of voting power in base 10000 needed to execute a proposal option
    // 100 == 1% 2500 == 25%
    uint256 public votingPowerPercentageForProposalExecution;

    // The percentage of voting power in base 10000 needed to create a proposal
    // 100 == 1% 2500 == 25%
    uint256 public votingPowerPercentageForProposalCreation;

    // The amount of gas in wei unit used for vote refunds
    uint256 public voteGas;

    // The maximum gas price used for vote refunds
    uint256 public maxGasPrice;

    // The maximum amount of proposals to be active at the same time
    uint256 public maxActiveProposals;

    // The total amount of proposals created, used as nonce for proposals creation
    uint256 public totalProposals;

    // The total amount of members that have voting power
    uint256 totalMembers;

    // The amount of active proposals
    uint256 public activeProposalsNow;

    // The amount of time in seconds that the voting tokens would be locked
    uint256 public lockTime;

    // The total amount of tokens locked
    uint256 public totalLocked;

    // The number of minimum guild members to be able to create a proposal
    uint256 public minimumMembersForProposalCreation;

    // The number of minimum tokens locked to be able to create a proposal
    uint256 public minimumTokensLockedForProposalCreation;

    // The address of the Token Vault contract, where tokens are being held for the users
    TokenVault public tokenVault;

    // The tokens locked indexed by token holder address.
    struct TokenLock {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => TokenLock) public tokensLocked;

    // All the signed votes that were executed, to avoid double signed vote execution.
    mapping(bytes32 => bool) public signedVotes;

    // Vote and Proposal structs used in the proposals mapping
    struct Vote {
        uint256 option;
        uint256 votingPower;
    }

    struct Proposal {
        address creator;
        uint256 startTime;
        uint256 endTime;
        address[] to;
        bytes[] data;
        uint256[] value;
        string title;
        string contentHash;
        ProposalState state;
        uint256[] totalVotes;
    }

    // Mapping of proposal votes
    mapping(bytes32 => mapping(address => Vote)) public proposalVotes;

    // Mapping of all proposals created indexed by proposal id
    mapping(bytes32 => Proposal) public proposals;

    // Array to keep track of the proposals ids in contract storage
    bytes32[] public proposalsIds;

    event ProposalStateChanged(bytes32 indexed proposalId, uint256 newState);
    event VoteAdded(bytes32 indexed proposalId, uint256 indexed option, address voter, uint256 votingPower);
    event TokensLocked(address voter, uint256 value);
    event TokensWithdrawn(address voter, uint256 value);

    bool internal isExecutingProposal;

    fallback() external payable {}

    // @dev Set the ERC20Guild configuration, can be called only executing a proposal or when it is initialized
    // @param _proposalTime The amount of time in seconds that a proposal will be active for voting
    // @param _timeForExecution The amount of time in seconds that a proposal option will have to execute successfully
    // @param _votingPowerPercentageForProposalExecution The percentage of voting power in base 10000 needed to execute a proposal
    // option
    // @param _votingPowerPercentageForProposalCreation The percentage of voting power in base 10000 needed to create a proposal
    // @param _voteGas The amount of gas in wei unit used for vote refunds.
    // Can't be higher than the gas used by setVote (117000)
    // @param _maxGasPrice The maximum gas price used for vote refunds
    // @param _maxActiveProposals The maximum amount of proposals to be active at the same time
    // @param _lockTime The minimum amount of seconds that the tokens would be locked
    function setConfig(
        uint256 _proposalTime,
        uint256 _timeForExecution,
        uint256 _votingPowerPercentageForProposalExecution,
        uint256 _votingPowerPercentageForProposalCreation,
        uint256 _voteGas,
        uint256 _maxGasPrice,
        uint256 _maxActiveProposals,
        uint256 _lockTime,
        uint256 _minimumMembersForProposalCreation,
        uint256 _minimumTokensLockedForProposalCreation
    ) external virtual {
        require(msg.sender == address(this), "ERC20Guild: Only callable by ERC20guild itself or when initialized");
        require(_proposalTime > 0, "ERC20Guild: proposal time has to be more than 0");
        require(_lockTime >= _proposalTime, "ERC20Guild: lockTime has to be higher or equal to proposalTime");
        require(
            _votingPowerPercentageForProposalExecution > 0,
            "ERC20Guild: voting power for execution has to be more than 0"
        );
        require(_voteGas <= 117000, "ERC20Guild: vote gas has to be equal or lower than 117000");
        proposalTime = _proposalTime;
        timeForExecution = _timeForExecution;
        votingPowerPercentageForProposalExecution = _votingPowerPercentageForProposalExecution;
        votingPowerPercentageForProposalCreation = _votingPowerPercentageForProposalCreation;
        voteGas = _voteGas;
        maxGasPrice = _maxGasPrice;
        maxActiveProposals = _maxActiveProposals;
        lockTime = _lockTime;
        minimumMembersForProposalCreation = _minimumMembersForProposalCreation;
        minimumTokensLockedForProposalCreation = _minimumTokensLockedForProposalCreation;
    }

    // @dev Create a proposal with an static call data and extra information
    // @param to The receiver addresses of each call to be executed
    // @param data The data to be executed on each call to be executed
    // @param value The ETH value to be sent on each call to be executed
    // @param totalOptions The amount of options that would be offered to the voters
    // @param title The title of the proposal
    // @param contentHash The content hash of the content reference of the proposal for the proposal to be executed
    function createProposal(
        address[] memory to,
        bytes[] memory data,
        uint256[] memory value,
        uint256 totalOptions,
        string memory title,
        string memory contentHash
    ) public virtual returns (bytes32) {
        require(
            totalLocked >= minimumTokensLockedForProposalCreation,
            "ERC20Guild: Not enough tokens locked to create a proposal"
        );

        require(
            totalMembers >= minimumMembersForProposalCreation,
            "ERC20Guild: Not enough members to create a proposal"
        );

        require(activeProposalsNow < getMaxActiveProposals(), "ERC20Guild: Maximum amount of active proposals reached");
        require(
            votingPowerOf(msg.sender) >= getVotingPowerForProposalCreation(),
            "ERC20Guild: Not enough votingPower to create proposal"
        );
        require(
            (to.length == data.length) && (to.length == value.length),
            "ERC20Guild: Wrong length of to, data or value arrays"
        );
        require(to.length > 0, "ERC20Guild: to, data value arrays cannot be empty");
        require(
            totalOptions <= to.length && value.length.mod(totalOptions) == 0,
            "ERC20Guild: Invalid totalOptions or option calls length"
        );
        require(totalOptions <= MAX_OPTIONS_PER_PROPOSAL, "ERC20Guild: Maximum amount of options per proposal reached");

        bytes32 proposalId = keccak256(abi.encodePacked(msg.sender, block.timestamp, totalProposals));
        totalProposals = totalProposals.add(1);
        Proposal storage newProposal = proposals[proposalId];
        newProposal.creator = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp.add(proposalTime);
        newProposal.to = to;
        newProposal.data = data;
        newProposal.value = value;
        newProposal.title = title;
        newProposal.contentHash = contentHash;
        newProposal.totalVotes = new uint256[](totalOptions.add(1));
        newProposal.state = ProposalState.Active;

        activeProposalsNow = activeProposalsNow.add(1);
        emit ProposalStateChanged(proposalId, uint256(ProposalState.Active));
        proposalsIds.push(proposalId);
        return proposalId;
    }

    // @dev Executes a proposal that is not votable anymore and can be finished
    // @param proposalId The id of the proposal to be executed
    function endProposal(bytes32 proposalId) public virtual {
        require(!isExecutingProposal, "ERC20Guild: Proposal under execution");
        require(proposals[proposalId].state == ProposalState.Active, "ERC20Guild: Proposal already executed");
        require(proposals[proposalId].endTime < block.timestamp, "ERC20Guild: Proposal hasn't ended yet");

        uint256 winningOption = 0;
        uint256 highestVoteAmount = proposals[proposalId].totalVotes[0];
        uint256 i = 1;
        for (i = 1; i < proposals[proposalId].totalVotes.length; i++) {
            if (
                proposals[proposalId].totalVotes[i] >= getVotingPowerForProposalExecution() &&
                proposals[proposalId].totalVotes[i] >= highestVoteAmount
            ) {
                if (proposals[proposalId].totalVotes[i] == highestVoteAmount) {
                    winningOption = 0;
                } else {
                    winningOption = i;
                    highestVoteAmount = proposals[proposalId].totalVotes[i];
                }
            }
        }

        if (winningOption == 0) {
            proposals[proposalId].state = ProposalState.Rejected;
            emit ProposalStateChanged(proposalId, uint256(ProposalState.Rejected));
        } else if (proposals[proposalId].endTime.add(timeForExecution) < block.timestamp) {
            proposals[proposalId].state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, uint256(ProposalState.Failed));
        } else {
            proposals[proposalId].state = ProposalState.Executed;

            uint256 callsPerOption = proposals[proposalId].to.length.div(
                proposals[proposalId].totalVotes.length.sub(1)
            );
            i = callsPerOption.mul(winningOption.sub(1));
            uint256 endCall = i.add(callsPerOption);

            permissionRegistry.setERC20Balances();

            for (i; i < endCall; i++) {
                if (proposals[proposalId].to[i] != address(0) && proposals[proposalId].data[i].length > 0) {
                    bytes memory _data = proposals[proposalId].data[i];
                    bytes4 callDataFuncSignature;
                    assembly {
                        callDataFuncSignature := mload(add(_data, 32))
                    }
                    // The permission registry keeps track of all value transferred and checks call permission
                    try
                        permissionRegistry.setETHPermissionUsed(
                            address(this),
                            proposals[proposalId].to[i],
                            bytes4(callDataFuncSignature),
                            proposals[proposalId].value[i]
                        )
                    {} catch Error(string memory reason) {
                        revert(reason);
                    }

                    isExecutingProposal = true;
                    // We use isExecutingProposal variable to avoid re-entrancy in proposal execution
                    // slither-disable-next-line all
                    (bool success, ) = proposals[proposalId].to[i].call{value: proposals[proposalId].value[i]}(
                        proposals[proposalId].data[i]
                    );
                    require(success, "ERC20Guild: Proposal call failed");
                    isExecutingProposal = false;
                }
            }

            permissionRegistry.checkERC20Limits(address(this));

            emit ProposalStateChanged(proposalId, uint256(ProposalState.Executed));
        }
        activeProposalsNow = activeProposalsNow.sub(1);
    }

    // @dev Set the voting power to vote in a proposal
    // @param proposalId The id of the proposal to set the vote
    // @param option The proposal option to be voted
    // @param votingPower The votingPower to use in the proposal
    function setVote(
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower
    ) public virtual {
        require(proposals[proposalId].endTime > block.timestamp, "ERC20Guild: Proposal ended, cannot be voted");
        require(
            (votingPowerOf(msg.sender) >= votingPower) &&
                (votingPower > proposalVotes[proposalId][msg.sender].votingPower),
            "ERC20Guild: Invalid votingPower amount"
        );
        require(
            (proposalVotes[proposalId][msg.sender].option == 0 &&
                proposalVotes[proposalId][msg.sender].votingPower == 0) ||
                (proposalVotes[proposalId][msg.sender].option == option &&
                    proposalVotes[proposalId][msg.sender].votingPower < votingPower),
            "ERC20Guild: Cannot change option voted, only increase votingPower"
        );
        _setVote(msg.sender, proposalId, option, votingPower);
    }

    // @dev Set the voting power to vote in a proposal using a signed vote
    // @param proposalId The id of the proposal to set the vote
    // @param option The proposal option to be voted
    // @param votingPower The votingPower to use in the proposal
    // @param voter The address of the voter
    // @param signature The signature of the hashed vote
    function setSignedVote(
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower,
        address voter,
        bytes memory signature
    ) public virtual {
        require(proposals[proposalId].endTime > block.timestamp, "ERC20Guild: Proposal ended, cannot be voted");
        bytes32 hashedVote = hashVote(voter, proposalId, option, votingPower);
        require(!signedVotes[hashedVote], "ERC20Guild: Already voted");
        require(voter == hashedVote.toEthSignedMessageHash().recover(signature), "ERC20Guild: Wrong signer");
        signedVotes[hashedVote] = true;
        require(
            (votingPowerOf(voter) >= votingPower) && (votingPower > proposalVotes[proposalId][voter].votingPower),
            "ERC20Guild: Invalid votingPower amount"
        );
        require(
            (proposalVotes[proposalId][voter].option == 0 && proposalVotes[proposalId][voter].votingPower == 0) ||
                (proposalVotes[proposalId][voter].option == option &&
                    proposalVotes[proposalId][voter].votingPower < votingPower),
            "ERC20Guild: Cannot change option voted, only increase votingPower"
        );
        _setVote(voter, proposalId, option, votingPower);
    }

    // @dev Lock tokens in the guild to be used as voting power
    // @param tokenAmount The amount of tokens to be locked
    function lockTokens(uint256 tokenAmount) external virtual {
        require(tokenAmount > 0, "ERC20Guild: Tokens to lock should be higher than 0");

        if (votingPowerOf(msg.sender) == 0) totalMembers = totalMembers.add(1);

        tokenVault.deposit(msg.sender, tokenAmount);
        tokensLocked[msg.sender].amount = tokensLocked[msg.sender].amount.add(tokenAmount);
        tokensLocked[msg.sender].timestamp = block.timestamp.add(lockTime);
        totalLocked = totalLocked.add(tokenAmount);

        emit TokensLocked(msg.sender, tokenAmount);
    }

    // @dev Withdraw tokens locked in the guild, this will decrease the voting power
    // @param tokenAmount The amount of tokens to be withdrawn
    function withdrawTokens(uint256 tokenAmount) external virtual {
        require(votingPowerOf(msg.sender) >= tokenAmount, "ERC20Guild: Unable to withdraw more tokens than locked");
        require(getVoterLockTimestamp(msg.sender) < block.timestamp, "ERC20Guild: Tokens still locked");
        require(tokenAmount > 0, "ERC20Guild: amount of tokens to withdraw must be greater than 0");

        tokensLocked[msg.sender].amount = tokensLocked[msg.sender].amount.sub(tokenAmount);
        totalLocked = totalLocked.sub(tokenAmount);
        tokenVault.withdraw(msg.sender, tokenAmount);

        if (votingPowerOf(msg.sender) == 0) totalMembers = totalMembers.sub(1);

        emit TokensWithdrawn(msg.sender, tokenAmount);
    }

    // @dev Internal function to set the amount of votingPower to vote in a proposal
    // @param voter The address of the voter
    // @param proposalId The id of the proposal to set the vote
    // @param option The proposal option to be voted
    // @param votingPower The amount of votingPower to use as voting for the proposal
    function _setVote(
        address voter,
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower
    ) internal {
        proposals[proposalId].totalVotes[option] = proposals[proposalId]
            .totalVotes[option]
            .sub(proposalVotes[proposalId][voter].votingPower)
            .add(votingPower);

        proposalVotes[proposalId][voter].option = option;
        proposalVotes[proposalId][voter].votingPower = votingPower;

        // Make sure tokens don't get unlocked before the proposal ends, to prevent double voting.
        if (getVoterLockTimestamp(voter) < proposals[proposalId].endTime) {
            tokensLocked[voter].timestamp = proposals[proposalId].endTime;
        }

        emit VoteAdded(proposalId, option, voter, votingPower);

        if (voteGas > 0) {
            uint256 gasRefund = voteGas.mul(tx.gasprice.min(maxGasPrice));

            if (address(this).balance >= gasRefund && !address(msg.sender).isContract()) {
                (bool success, ) = payable(msg.sender).call{value: gasRefund}("");
                require(success, "Failed to refund gas");
            }
        }
    }

    // @dev Get the information of a proposal
    // @param proposalId The id of the proposal to get the information
    // @return creator The address that created the proposal
    // @return startTime The time at the proposal was created
    // @return endTime The time at the proposal will end
    // @return to The receiver addresses of each call to be executed
    // @return data The data to be executed on each call to be executed
    // @return value The ETH value to be sent on each call to be executed
    // @return title The title of the proposal
    // @return contentHash The content hash of the content reference of the proposal
    // @return state If the proposal state
    // @return totalVotes The total votes of the proposal
    function getProposal(bytes32 proposalId) external view virtual returns (Proposal memory) {
        return (proposals[proposalId]);
    }

    // @dev Get the voting power of an account
    // @param account The address of the account
    function votingPowerOf(address account) public view virtual returns (uint256) {
        return tokensLocked[account].amount;
    }

    // @dev Get the address of the ERC20Token used for voting
    function getToken() external view returns (address) {
        return address(token);
    }

    // @dev Get the address of the permission registry contract
    function getPermissionRegistry() external view returns (address) {
        return address(permissionRegistry);
    }

    // @dev Get the name of the ERC20Guild
    function getName() external view returns (string memory) {
        return name;
    }

    // @dev Get the proposalTime
    function getProposalTime() external view returns (uint256) {
        return proposalTime;
    }

    // @dev Get the timeForExecution
    function getTimeForExecution() external view returns (uint256) {
        return timeForExecution;
    }

    // @dev Get the voteGas
    function getVoteGas() external view returns (uint256) {
        return voteGas;
    }

    // @dev Get the maxGasPrice
    function getMaxGasPrice() external view returns (uint256) {
        return maxGasPrice;
    }

    // @dev Get the maxActiveProposals
    function getMaxActiveProposals() public view returns (uint256) {
        return maxActiveProposals;
    }

    // @dev Get the totalProposals
    function getTotalProposals() external view returns (uint256) {
        return totalProposals;
    }

    // @dev Get the totalMembers
    function getTotalMembers() public view returns (uint256) {
        return totalMembers;
    }

    // @dev Get the activeProposalsNow
    function getActiveProposalsNow() external view returns (uint256) {
        return activeProposalsNow;
    }

    function getMinimumMembersForProposalCreation() external view returns (uint256) {
        return minimumMembersForProposalCreation;
    }

    function getMinimumTokensLockedForProposalCreation() external view returns (uint256) {
        return minimumTokensLockedForProposalCreation;
    }

    // @dev Get if a signed vote has been executed or not
    function getSignedVote(bytes32 signedVoteHash) external view returns (bool) {
        return signedVotes[signedVoteHash];
    }

    // @dev Get the proposalsIds array
    function getProposalsIds() external view returns (bytes32[] memory) {
        return proposalsIds;
    }

    // @dev Get the votes of a voter in a proposal
    // @param proposalId The id of the proposal to get the information
    // @param voter The address of the voter to get the votes
    // @return option The selected option of teh voter
    // @return votingPower The amount of voting power used in the vote
    function getProposalVotesOfVoter(bytes32 proposalId, address voter)
        external
        view
        virtual
        returns (uint256 option, uint256 votingPower)
    {
        return (proposalVotes[proposalId][voter].option, proposalVotes[proposalId][voter].votingPower);
    }

    // @dev Get minimum amount of votingPower needed for creation
    function getVotingPowerForProposalCreation() public view virtual returns (uint256) {
        return getTotalLocked().mul(votingPowerPercentageForProposalCreation).div(10000);
    }

    // @dev Get minimum amount of votingPower needed for proposal execution
    function getVotingPowerForProposalExecution() public view virtual returns (uint256) {
        return getTotalLocked().mul(votingPowerPercentageForProposalExecution).div(10000);
    }

    // @dev Get the length of the proposalIds array
    function getProposalsIdsLength() external view virtual returns (uint256) {
        return proposalsIds.length;
    }

    // @dev Get the tokenVault address
    function getTokenVault() external view virtual returns (address) {
        return address(tokenVault);
    }

    // @dev Get the lockTime
    function getLockTime() external view virtual returns (uint256) {
        return lockTime;
    }

    // @dev Get the totalLocked
    function getTotalLocked() public view virtual returns (uint256) {
        return totalLocked;
    }

    // @dev Get the locked timestamp of a voter tokens
    function getVoterLockTimestamp(address voter) public view virtual returns (uint256) {
        return tokensLocked[voter].timestamp;
    }

    // @dev Get the hash of the vote, this hash is later signed by the voter.
    // @param voter The address that will be used to sign the vote
    // @param proposalId The id fo the proposal to be voted
    // @param option The proposal option to be voted
    // @param votingPower The amount of voting power to be used
    function hashVote(
        address voter,
        bytes32 proposalId,
        uint256 option,
        uint256 votingPower
    ) public pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(voter, proposalId, option, votingPower));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}