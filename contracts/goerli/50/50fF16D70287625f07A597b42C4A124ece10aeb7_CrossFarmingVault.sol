// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "./CrossFarmingSender.sol";

/// @title A vault contract which deployed on EVM chain(Not BSC chain), user can stake LP token from liquidity pool
/// in EVM chain to participate MasterchefV2 farm pools(BSC chain), get native CAKE reward in BSC chain.
/// @dev deployed on EVM chain(source chain, not BSC chain).
contract CrossFarmingVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // user deposit original LP token amount.
        uint256 lastActionTime;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 mcv2PoolId; // pool id in Pancakeswap MastercherV2 farms.
        uint256 totalAmount; // total staked LP token amount.
    }

    // cross farming sender contract deployed on other EVM chain(none bsc chain)
    // which send cross-chain msg to celer messagebus deployed on EVM chain.
    address public CROSS_FARMING_SENDER;
    // cross farming receiver contract deployed on BSC chain
    // which receive cross-chain msg from celer messagebus deployed on BSC chain.
    address public CROSS_FARMING_RECEIVER;
    // BSC chain ID
    uint64 public immutable BSC_CHAIN_ID;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // whether LP tokend added to pool
    mapping(IERC20 => bool) public exists;
    // MCV2 pool 1:1 vault pool, one more pool can't share same pool reward in MCV2.
    mapping(uint256 => bool) public mappinged;

    event Pause();
    event Unpause();
    event AddedPool(address indexed lpToken, uint256 mockPoolId);
    event Harvest(address indexed sender, uint256 pid);
    event Withdraw(address indexed sender, uint256 pid, uint256 amount);
    event EmergencyWithdraw(address indexed sender, uint256 pid, uint256 amount);
    event Deposit(address indexed sender, uint256 pid, uint256 amount, uint256 lastDepositedTime);
    event FarmingContractUpdated(address indexed sender, address senderContract, address receiverContract);

    /**
     * @param _sender: cross farming sender contract on EVM chain
     * @param _receiver: cross farming receiver contract on BSC
     * @param _chainId: BSC chain ID
     */
    constructor(
        address _sender,
        address _receiver,
        uint64 _chainId
    ) {
        CROSS_FARMING_SENDER = _sender;
        CROSS_FARMING_RECEIVER = _receiver;
        BSC_CHAIN_ID = _chainId;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Add lp token and pool id corresponding to masterchefv2 farm pool.
     * @dev same token can't be added repeatedly.
     * @param _lpToken lp token address.
     * @param _mcv2PoolId pool id in masterchefv2 farm pool.
     */
    function add(IERC20 _lpToken, uint256 _mcv2PoolId) public onlyOwner {
        require(_mcv2PoolId != 0, "Invalid pool id");
        require(!exists[_lpToken], "Token added");
        require(!mappinged[_mcv2PoolId], "MCV2 pool mappinged");
        require(_lpToken.balanceOf(address(this)) >= 0, "None ERC20 token");

        poolInfo.push(PoolInfo({lpToken: _lpToken, mcv2PoolId: _mcv2PoolId, totalAmount: 0}));
        exists[_lpToken] = true;
        mappinged[_mcv2PoolId] = true;

        emit AddedPool(address(_lpToken), _mcv2PoolId);
    }

    /**
     * @notice deposit funds into current vault.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount deposit token amount.
     */
    function deposit(uint256 _pid, uint256 _amount) external payable whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // transfer token
        IERC20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);

        // encode farming message
        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            _amount,
            CrossFarmingSender.MessageTypes.Deposit
        );

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature(
                "sendFarmMessage(address,bytes,uint64)",
                CROSS_FARMING_RECEIVER,
                message,
                BSC_CHAIN_ID
            )
        );

        require(success, "send deposit farm message failed");

        // update poolInfo
        pool.totalAmount = pool.totalAmount + _amount;
        // update userInfo
        user.amount = user.amount + _amount;
        user.lastActionTime = block.timestamp;

        emit Deposit(msg.sender, _pid, _amount, block.timestamp);
    }

    /**
     * @notice withdraw funds from the current vault.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount withdraw token amount.
     */
    function withdraw(uint256 _pid, uint256 _amount) external payable whenNotPaused notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount && _amount > 0, "Insufficient amount");

        // transfer LP token
        IERC20(pool.lpToken).safeTransfer(msg.sender, _amount);

        // encode farming message
        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            _amount,
            CrossFarmingSender.MessageTypes.Withdraw
        );

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature(
                "sendFarmMessage(address,bytes,uint64)",
                CROSS_FARMING_RECEIVER,
                message,
                BSC_CHAIN_ID
            )
        );

        require(success, "send withdraw farm message failed");

        // update poolInfo
        pool.totalAmount = pool.totalAmount - _amount;
        // update userInfo
        user.amount -= _amount;
        user.lastActionTime = block.timestamp;

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @notice EmergencyWithdraws tokens from the current contract.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     */
    function emergencyWithdraw(uint256 _pid) external payable whenNotPaused notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "No fund left");

        uint256 withdrawAmount = user.amount;
        // transfer token
        IERC20(pool.lpToken).safeTransfer(msg.sender, withdrawAmount);

        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            withdrawAmount,
            CrossFarmingSender.MessageTypes.EmergencyWithdraw
        );

        // send farming message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature(
                "sendFarmMessage(address,bytes,uint64)",
                CROSS_FARMING_RECEIVER,
                message,
                BSC_CHAIN_ID
            )
        );

        require(success, "send emergencyWithdraw farm message failed");

        // totalAmount > withdrawAmount
        pool.totalAmount -= withdrawAmount;
        // update userInfo
        user.amount = 0;
        user.lastActionTime = block.timestamp;

        emit EmergencyWithdraw(msg.sender, _pid, withdrawAmount);
    }

    /**
     * @notice claim CAKE reward in MCV2 farm pool, not withdraw LP token.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     */
    function harvest(uint256 _pid) external payable whenNotPaused notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "No fund to harvest");

        // encode farming message
        bytes memory message = encodeMessage(msg.sender, pool.mcv2PoolId, 0, CrossFarmingSender.MessageTypes.Harvest);

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature(
                "sendFarmMessage(address,bytes,uint64)",
                CROSS_FARMING_RECEIVER,
                message,
                BSC_CHAIN_ID
            )
        );

        require(success, "send harvest farm message failed");

        emit Harvest(msg.sender, _pid);
    }

    /// @notice
    /**
     * @notice update cross farming contract address.
     * @param _crossSender cross-chain contract on source chain.
     * @param _crossReceiver cross-chain contract on dest chain.
     */
    function setCrossFarmingContract(address _crossSender, address _crossReceiver) external onlyOwner {
        require(
            address(_crossSender) != address(0) && address(_crossReceiver) != address(0),
            "Invalid farming contract"
        );

        CROSS_FARMING_SENDER = _crossSender;
        CROSS_FARMING_RECEIVER = _crossReceiver;

        emit FarmingContractUpdated(msg.sender, _crossSender, _crossReceiver);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice utility interface for FE to calc routing message fee charged by celer.
     * @param _message encoded cross-farm  message
     */
    function calcFee(bytes calldata _message) external view returns (uint256) {
        address messageBus = CrossFarmingSender(CROSS_FARMING_SENDER).messageBus();
        return IMessageBus(messageBus).calcFee(_message);
    }

    /**
     * @notice utility interface for FE to encode cross-farming message.
     * @param _account cross-farm user account.
     * @param _pid mock pool id in Pancake MasterchefV2.
     * @param _amount the input token amount.
     * @param _msgType farm message type.
     */
    function encodeMessage(
        address _account,
        uint256 _pid,
        uint256 _amount,
        CrossFarmingSender.MessageTypes _msgType
    ) public view returns (bytes memory) {
        return
            abi.encode(
                CrossFarmingSender(CROSS_FARMING_SENDER).nonces(_account, _pid),
                CrossFarmingSender.CrossFarmRequest({account: _account, amount: _amount, pid: _pid, msgType: _msgType})
            );
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../libraries/MsgDataTypes.sol";

interface IMessageBus {
    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "sgn-v2-contracts/contracts/message/framework/MessageSenderApp.sol";
import "sgn-v2-contracts/contracts/message/framework/MessageReceiverApp.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title A cross chain contract for users from other EVM chain participate Pancakeswap MCV2 farm pool in BSC chain.
/// @dev deployed on EVM chain(source chain, not BSC chain).
contract CrossFarmingSender is MessageSenderApp, MessageReceiverApp {
    using SafeERC20 for IERC20;

    enum MessageTypes {
        Deposit,
        Withdraw,
        EmergencyWithdraw,
        Harvest
    }

    // oracle data feeds
    enum Feeds {
        BNBUSD,
        ETHUSD
    }

    struct CrossFarmRequest {
        address account;
        uint256 pid;
        uint256 amount;
        MessageTypes msgType;
    }

    // cross farming vault contract on EVM chain.
    address public Vault;

    // create proxy contract on dest chain(BSC) gas limit.
    uint256 public createProxyGasLimit;
    // gas fee = gaslimit * gasprice, different EVM chain,transaction have different average gas price
    // gasFeeFloatRate is a range([0.1,10]) rate for convert gas fee from source chain  to dest chain.
    // for example, source chain gas price is 1/2 dest chain gas price, so the user paid txfee in sourcechain
    // should base on 2x gas fee in destchain.
    uint256 public txFeeFloatRate;
    // Gas fee float rate precision.(100%)
    uint256 public constant FLOAT_RATE_PRECISION = 1e5;
    // Max float rate(1000%)
    uint256 public constant MAX_FLOAT_RATE = 10e5;
    // Minimize float rate(10%)
    uint256 public constant MIN_FLOAT_RATE = 1e4;
    // Small BNB change for the new user in BSC chain.
    uint256 public BNB_CHANGE = 0.005 ether;
    // ETH/BNB price exchange rate precison
    uint256 public constant EXCHANGE_RATE_PRECISION = 1e5;
    // BSC chain ID
    uint64 public immutable BSC_CHAIN_ID;

    // oracle data feeds
    mapping(Feeds => AggregatorV3Interface) public oracle;
    // oracle latest roundId for different feed
    mapping(Feeds => uint256) public latestRoundId;
    // oracle data feeds update time buffer
    mapping(Feeds => uint256) public oracleUpdateBuffer;
    // user pool nonce info(account => (pid => nonce))
    mapping(address => mapping(uint256 => uint64)) public nonces;
    // whether user sent the 1st cross-chain tx.
    mapping(address => bool) public is1st;
    // different message(operation) type have different estimate gas limit in BSC chain.
    // should be updated when EVM upgraded and gaslimit change a lot.
    mapping(MessageTypes => uint256) public gaslimits;

    event NewOracle(address oracle);
    event VaultUpdated(address vault);
    event FeeClaimed(uint256 amount);
    event FloatRateUpdated(uint256 rate);
    event BnbChangeUpdated(uint256 amount);
    event CreateProxyGasLimitUpdated(uint256 gaslimit);
    event OracleBufferUpdated(Feeds feed, uint256 oracleUpdateBuffer);
    event GasLimitUpdated(MessageTypes msgtype, uint256 gaslimit);

    constructor(
        address _messageBus,
        address _oracle_bnb,
        address _oracle_eth,
        uint256 _oracle_bnb_update_buffer,
        uint256 _oracle_eth_update_buffer,
        uint64 _chainId
    ) {
        messageBus = _messageBus;
        oracle[Feeds.BNBUSD] = AggregatorV3Interface(_oracle_bnb);
        oracle[Feeds.ETHUSD] = AggregatorV3Interface(_oracle_eth);
        oracleUpdateBuffer[Feeds.BNBUSD] = _oracle_bnb_update_buffer;
        oracleUpdateBuffer[Feeds.ETHUSD] = _oracle_eth_update_buffer;
        // initially, float rate is 100%
        txFeeFloatRate = FLOAT_RATE_PRECISION;
        BSC_CHAIN_ID = _chainId;
    }

    modifier onlyVault() {
        require(msg.sender == Vault, "Only vault contract");
        _;
    }

    /**
     * @notice Only called by Vault contract.
     * @param _receiver destination cross-farm contract address
     * @param _message encoded messages
     * @param _dstChainId destination chain id
     */
    function sendFarmMessage(
        address _receiver,
        bytes calldata _message,
        uint64 _dstChainId
    ) external payable onlyVault {
        // decode the message
        (uint64 nonce, CrossFarmRequest memory request) = abi.decode((_message), (uint64, CrossFarmRequest));
        require(nonce == nonces[request.account][request.pid], "Invalid nonce");

        // ETH/USD price
        int256 ethPrice = _getPriceFromOracle(Feeds.ETHUSD);
        // BNB/USD price
        int256 bnbPrice = _getPriceFromOracle(Feeds.BNBUSD);

        require(bnbPrice > 0 && ethPrice > 0, "Abnormal prices");

        uint256 exchangeRate = (uint256(bnbPrice) * EXCHANGE_RATE_PRECISION) / uint256(ethPrice);

        uint256 msgBusFee = IMessageBus(messageBus).calcFee(_message);

        uint256 totalFee = msgBusFee +
            // destTxFee
            (tx.gasprice * estimateDestGaslimit(request.account, request.msgType) * exchangeRate * txFeeFloatRate) /
            (EXCHANGE_RATE_PRECISION * FLOAT_RATE_PRECISION);

        // BNB change fee for new BNB user
        if (!is1st[request.account]) {
            totalFee += (BNB_CHANGE * exchangeRate) / EXCHANGE_RATE_PRECISION;
            is1st[request.account] = true;
        }

        require(msg.value >= totalFee, "Insufficient fee");

        IMessageBus(messageBus).sendMessage{value: msgBusFee}(_receiver, _dstChainId, _message);

        nonces[request.account][request.pid] += 1;
    }

    // set cross farming vault contract on source chain.
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault contract can't be zero address");
        Vault = _vault;

        emit VaultUpdated(Vault);
    }

    /// set oracle data feeds.
    function setOracle(Feeds _feed, address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle feed can't be zero address");
        latestRoundId[_feed] = 0;
        oracle[_feed] = AggregatorV3Interface(_oracle);

        // Dummy check to make sure the interface implements this function properly
        oracle[_feed].latestRoundData();

        emit NewOracle(_oracle);
    }

    /// set oracle update buffer, different oracle feeds have different update frequency,
    /// so the buffer should also change accordingly
    function setOracleUpdateBuffer(Feeds _feed, uint256 _oracleUpdateBuffer) external onlyOwner {
        require(_oracleUpdateBuffer > 0, "oracle update time buffer should > 0");
        oracleUpdateBuffer[_feed] = _oracleUpdateBuffer;
        emit OracleBufferUpdated(_feed, _oracleUpdateBuffer);
    }

    /// set gas limit for different operation.
    function setGaslimits(MessageTypes _type, uint256 _gaslimit) external onlyOwner {
        require(_gaslimit > 0, "Gaslimit should be > zero");
        gaslimits[_type] = _gaslimit;
        emit GasLimitUpdated(_type, _gaslimit);
    }

    /// @notice gas price and gas limit will change in differenct chain,
    /// the tx fee float rate should change accordingly to prevent run out of gas.
    function setFloatRate(uint256 _rate) external onlyOwner {
        require(_rate >= MIN_FLOAT_RATE && _rate <= MAX_FLOAT_RATE, "Invalid float rate");
        txFeeFloatRate = _rate;
        emit FloatRateUpdated(txFeeFloatRate);
    }

    /// set BNB change amount for new BSC chain user.
    function setBnbChange(uint256 _change) external onlyOwner {
        require(_change > 0, "BNB change for new user should greater than zero");
        BNB_CHANGE = _change;
        emit BnbChangeUpdated(_change);
    }

    /// create farming-proxy contract gas limit cost in BSC chain.
    function setCreateProxyGasLimit(uint256 _gaslimit) external onlyOwner {
        createProxyGasLimit = _gaslimit;
        emit CreateProxyGasLimitUpdated(_gaslimit);
    }

    /// estimate different operation consume gas limit in BSC chain.
    /// @notice called on source chain.
    function estimateDestGaslimit(address _account, MessageTypes _msgType) public view returns (uint256 gaslimit) {
        gaslimit = gaslimits[_msgType];
        // 1st cross-chain tx should add create proxy gaslimit.
        if (!is1st[_account]) gaslimit += createProxyGasLimit;
    }

    /// transfer any ERC20 token of current contract to owner.
    function drainToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// send cross-chain sender contract all gas token to owner
    function claimFee() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit FeeClaimed(amount);
    }

    /**
     * @notice Get latest recorded price from oracle and update round id.
     */
    function _getPriceFromOracle(Feeds _feed) internal returns (int256) {
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle[_feed].latestRoundData();
        require(timestamp + oracleUpdateBuffer[_feed] >= block.timestamp, "out of date oracle data ");
        // update latest round id
        if (uint256(roundId) > latestRoundId[_feed]) {
            latestRoundId[_feed] = roundId;
        }
        return price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

library MsgDataTypes {
    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/MsgDataTypes.sol";
import "../libraries/MessageSenderLib.sol";
import "../messagebus/MessageBus.sol";
import "./MessageBusAddress.sol";

abstract contract MessageSenderApp is MessageBusAddress {
    using SafeERC20 for IERC20;

    // ============== Utility functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        uint256 _fee
    ) internal {
        MessageSenderLib.sendMessage(_receiver, _dstChainId, _message, messageBus, _fee);
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        uint256 _fee
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _message,
                _bridgeSendType,
                messageBus,
                _fee
            );
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType
    ) internal {
        address bridge;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            bridge = MessageBus(messageBus).liquidityBridge();
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            bridge = MessageBus(messageBus).pegVault();
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            bridge = MessageBus(messageBus).pegBridge();
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit) {
            bridge = MessageBus(messageBus).pegVaultV2();
        } else if (
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn ||
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2BurnFrom
        ) {
            bridge = MessageBus(messageBus).pegBridgeV2();
        } else {
            revert("bridge type not supported");
        }
        MessageSenderLib.sendTokenTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _bridgeSendType,
            bridge
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../interfaces/IMessageReceiverApp.sol";
import "./MessageBusAddress.sol";

abstract contract MessageReceiverApp is IMessageReceiverApp, MessageBusAddress {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageBus.sol";
import "./MsgDataTypes.sol";

library MessageSenderLib {
    using SafeERC20 for IERC20;

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(_receiver, _dstChainId, _message);
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            return
                sendMessageWithLiquidityBridgeTransfer(
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _maxSlippage,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit ||
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit
        ) {
            return
                sendMessageWithPegVaultDeposit(
                    _bridgeSendType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn ||
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn
        ) {
            return
                sendMessageWithPegBridgeBurn(
                    _bridgeSendType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else {
            revert("bridge type not supported");
        }
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated liquidity bridge transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithLiquidityBridgeTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address bridge = IMessageBus(_messageBus).liquidityBridge();
        IERC20(_token).safeIncreaseAllowance(bridge, _amount);
        IBridge(bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
        );
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            bridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated OriginalTokenVault deposit.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegVaultDeposit(
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegVault;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            pegVault = IMessageBus(_messageBus).pegVault();
        } else {
            pegVault = IMessageBus(_messageBus).pegVaultV2();
        }
        IERC20(_token).safeIncreaseAllowance(pegVault, _amount);
        bytes32 transferId;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            IOriginalTokenVault(pegVault).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
        } else {
            transferId = IOriginalTokenVaultV2(pegVault).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        }
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegVault,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated PeggedTokenBridge burn.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegBridgeBurn(
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegBridge;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            pegBridge = IMessageBus(_messageBus).pegBridge();
        } else {
            pegBridge = IMessageBus(_messageBus).pegBridgeV2();
        }
        IERC20(_token).safeIncreaseAllowance(pegBridge, _amount);
        bytes32 transferId;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            IPeggedTokenBridge(pegBridge).burn(_token, _amount, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid))
            );
        } else {
            transferId = IPeggedTokenBridgeV2(pegBridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
        }
        // handle cases where certain tokens do not spend allowance for role-based burn
        IERC20(_token).safeApprove(pegBridge, 0);
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegBridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _bridge
    ) internal {
        IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            IBridge(_bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            IOriginalTokenVault(_bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            IPeggedTokenBridge(_bridge).burn(_token, _amount, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit) {
            IOriginalTokenVaultV2(_bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn) {
            IPeggedTokenBridgeV2(_bridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2BurnFrom) {
            IPeggedTokenBridgeV2(_bridge).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else {
            revert("bridge type not supported");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./MessageBusSender.sol";
import "./MessageBusReceiver.sol";

contract MessageBus is MessageBusSender, MessageBusReceiver {
    constructor(
        ISigsVerifier _sigsVerifier,
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    )
        MessageBusSender(_sigsVerifier)
        MessageBusReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2)
    {}

    // this is only to be called by Proxy via delegateCall as initOwner will require _owner is 0.
    // so calling init on this contract directly will guarantee to fail
    function init(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) external {
        // MUST manually call ownable init and must only call once
        initOwner();
        // we don't need sender init as _sigsVerifier is immutable so already in the deployed code
        initReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../../safeguard/Ownable.sol";

abstract contract MessageBusAddress is Ownable {
    event MessageBusUpdated(address messageBus);

    address public messageBus;

    function setMessageBus(address _messageBus) public onlyOwner {
        messageBus = _messageBus;
        emit MessageBusUpdated(messageBus);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../../safeguard/Ownable.sol";
import "../../interfaces/ISigsVerifier.sol";

contract MessageBusSender is Ownable {
    ISigsVerifier public immutable sigsVerifier;

    uint256 public feeBase;
    uint256 public feePerByte;
    mapping(address => uint256) public withdrawnFees;

    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);

    event MessageWithTransfer(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        address bridge,
        bytes32 srcTransferId,
        bytes message,
        uint256 fee
    );

    event FeeBaseUpdated(uint256 feeBase);
    event FeePerByteUpdated(uint256 feePerByte);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        emit Message(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        // SGN needs to verify
        // 1. msg.sender matches sender of the src transfer
        // 2. dstChainId matches dstChainId of the src transfer
        // 3. bridge is either liquidity bridge, peg src vault, or peg dst bridge
        emit MessageWithTransfer(msg.sender, _receiver, _dstChainId, _srcBridge, _srcTransferId, _message, msg.value);
    }

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "withdrawFee"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _account, _cumulativeFee), _sigs, _signers, _powers);
        uint256 amount = _cumulativeFee - withdrawnFees[_account];
        require(amount > 0, "No new amount to withdraw");
        withdrawnFees[_account] = _cumulativeFee;
        (bool sent, ) = _account.call{value: amount, gas: 50000}("");
        require(sent, "failed to withdraw fee");
    }

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) public view returns (uint256) {
        return feeBase + _message.length * feePerByte;
    }

    // -------------------- Admin --------------------

    function setFeePerByte(uint256 _fee) external onlyOwner {
        feePerByte = _fee;
        emit FeePerByteUpdated(feePerByte);
    }

    function setFeeBase(uint256 _fee) external onlyOwner {
        feeBase = _fee;
        emit FeeBaseUpdated(feeBase);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../libraries/MsgDataTypes.sol";
import "../interfaces/IMessageReceiverApp.sol";
import "../interfaces/IMessageBus.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../../safeguard/Ownable.sol";

contract MessageBusReceiver is Ownable {
    mapping(bytes32 => MsgDataTypes.TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address
    address public pegBridgeV2; // peg bridge address
    address public pegVaultV2; // peg original vault address

    // minimum amount of gas needed by this contract before it tries to
    // deliver a message to the target contract.
    uint256 public preExecuteMessageGasUsage;

    event Executed(
        MsgDataTypes.MsgType msgType,
        bytes32 msgId,
        MsgDataTypes.TxStatus status,
        address indexed receiver,
        uint64 srcChainId,
        bytes32 srcTxHash
    );
    event NeedRetry(MsgDataTypes.MsgType msgType, bytes32 msgId, uint64 srcChainId, bytes32 srcTxHash);
    event CallReverted(string reason); // help debug

    event LiquidityBridgeUpdated(address liquidityBridge);
    event PegBridgeUpdated(address pegBridge);
    event PegVaultUpdated(address pegVault);
    event PegBridgeV2Updated(address pegBridgeV2);
    event PegVaultV2Updated(address pegVaultV2);

    constructor(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) {
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    function initReceiver(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) internal {
        require(liquidityBridge == address(0), "liquidityBridge already set");
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    // ============== functions called by executor ==============

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // For message with token transfer, message Id is computed through transfer info
        // in order to guarantee that each transfer can only be used once.
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransfer"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransfer(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            est = executeMessageWithTransferFallback(_transfer, _message);
            if (est == IMessageReceiverApp.ExecutionStatus.Success) {
                status = MsgDataTypes.TxStatus.Fallback;
            } else {
                status = MsgDataTypes.TxStatus.Fail;
            }
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // similar to executeMessageWithTransfer
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransferRefund"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransferRefund(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message without associated token transfer, message Id is computed through message info,
        // in order to guarantee that each message can only be applied once
        bytes32 messageId = computeMessageOnlyId(_route, _message);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "message already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Message"));
        IBridge(liquidityBridge).verifySigs(abi.encodePacked(domain, messageId), _sigs, _signers, _powers);
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessage(_route, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(MsgDataTypes.MsgType.MessageOnly, messageId, _route.srcChainId, _route.srcTxHash);
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageOnlyExecutedEvent(messageId, status, _route);
    }

    // ================= utils (to avoid stack too deep) =================

    function emitMessageWithTransferExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.TransferInfo calldata _transfer
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageWithTransfer,
            _messageId,
            _status,
            _transfer.receiver,
            _transfer.srcChainId,
            _transfer.srcTxHash
        );
    }

    function emitMessageOnlyExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.RouteInfo calldata _route
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageOnly,
            _messageId,
            _status,
            _route.receiver,
            _route.srcChainId,
            _route.srcTxHash
        );
    }

    function executeMessageWithTransfer(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransfer.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferFallback(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferFallback.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferRefund(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferRefund.selector,
                _transfer.token,
                _transfer.amount,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function verifyTransfer(MsgDataTypes.TransferInfo calldata _transfer) private view returns (bytes32) {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == MsgDataTypes.TransferType.LqRelay) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).transfers(transferId) == true, "bridge relay not exist");
        } else if (_transfer.t == MsgDataTypes.TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.wdseq,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).withdraws(transferId) == true, "bridge withdraw not exist");
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegMint || _transfer.t == MsgDataTypes.TransferType.PegWithdraw
        ) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegMint) {
                bridgeAddr = pegBridge;
                require(IPeggedTokenBridge(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // _transfer.t == MsgDataTypes.TransferType.PegWithdraw
                bridgeAddr = pegVault;
                require(IOriginalTokenVault(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegV2Mint || _transfer.t == MsgDataTypes.TransferType.PegV2Withdraw
        ) {
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                bridgeAddr = pegBridgeV2;
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                bridgeAddr = pegVaultV2;
            }
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId,
                    bridgeAddr
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                require(IPeggedTokenBridgeV2(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                require(IOriginalTokenVaultV2(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        }
        return keccak256(abi.encodePacked(MsgDataTypes.MsgType.MessageWithTransfer, bridgeAddr, transferId));
    }

    function computeMessageOnlyId(MsgDataTypes.RouteInfo calldata _route, bytes calldata _message)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    MsgDataTypes.MsgType.MessageOnly,
                    _route.sender,
                    _route.receiver,
                    _route.srcChainId,
                    _route.srcTxHash,
                    uint64(block.chainid),
                    _message
                )
            );
    }

    function executeMessage(MsgDataTypes.RouteInfo calldata _route, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_route.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessage.selector,
                _route.sender,
                _route.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function handleExecutionRevert(uint256 _gasLeftBeforeExecution, bytes memory _returnData) private {
        uint256 gasLeftAfterExecution = gasleft();
        uint256 maxTargetGasLimit = block.gaslimit - preExecuteMessageGasUsage;
        if (_gasLeftBeforeExecution < maxTargetGasLimit && gasLeftAfterExecution <= _gasLeftBeforeExecution / 64) {
            // if this happens, the executor must have not provided sufficient gas limit,
            // then the tx should revert instead of recording a non-retryable failure status
            // https://github.com/wolflo/evm-opcodes/blob/main/gas.md#aa-f-gas-to-send-with-call-operations
            assembly {
                invalid()
            }
        }
        emit CallReverted(getRevertMsg(_returnData));
    }

    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    // ================= helper functions =====================

    /**
     * @notice combine bridge transfer and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer
     * @param _msgParams params to execute message
     */
    function transferAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransfer(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    /**
     * @notice combine bridge refund and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer for refund
     * @param _msgParams params to execute message for refund
     */
    function refundAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransferRefund(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    function _bridgeTransfer(MsgDataTypes.TransferType t, MsgDataTypes.BridgeTransferParams calldata _transferParams)
        private
    {
        if (t == MsgDataTypes.TransferType.LqRelay) {
            IBridge(liquidityBridge).relay(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.LqWithdraw) {
            IBridge(liquidityBridge).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegMint) {
            IPeggedTokenBridge(pegBridge).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Mint) {
            IPeggedTokenBridgeV2(pegBridgeV2).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegWithdraw) {
            IOriginalTokenVault(pegVault).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Withdraw) {
            IOriginalTokenVaultV2(pegVaultV2).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        }
    }

    // ================= contract config =================

    function setLiquidityBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        liquidityBridge = _addr;
        emit LiquidityBridgeUpdated(liquidityBridge);
    }

    function setPegBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridge = _addr;
        emit PegBridgeUpdated(pegBridge);
    }

    function setPegVault(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVault = _addr;
        emit PegVaultUpdated(pegVault);
    }

    function setPegBridgeV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridgeV2 = _addr;
        emit PegBridgeV2Updated(pegBridgeV2);
    }

    function setPegVaultV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVaultV2 = _addr;
        emit PegVaultV2Updated(pegVaultV2);
    }

    function setPreExecuteMessageGasUsage(uint256 _usage) public onlyOwner {
        preExecuteMessageGasUsage = _usage;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

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
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver) if the process is originated from MessageBus (MessageBusSender)'s
     *         sendMessageWithTransfer it is only called when the tokens are checked to be arrived at this contract's address.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Only called by MessageBus (MessageBusReceiver) if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     *        the contract that implements this contract can safely assume that the tokens will arrive before this
     *        function is called.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}