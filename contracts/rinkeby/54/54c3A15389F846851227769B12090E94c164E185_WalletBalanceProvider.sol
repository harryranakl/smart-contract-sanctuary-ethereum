// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Address} from "../dependencies/openzeppelin/contracts/Address.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {GPv2SafeERC20} from "../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title WalletBalanceProvider contract
 * , influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE ParaSpace PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the ParaSpace backend.
 **/
contract WalletBalanceProvider {
    using Address for address payable;
    using Address for address;
    using GPv2SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address constant MOCK_ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
    @dev Fallback function, don't accept any ETH
    **/
    receive() external payable {
        //only contracts can send ETH to the core
        require(msg.sender.isContract(), "22");
    }

    /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
    function balanceOf(address user, address token)
        public
        view
        returns (uint256)
    {
        if (token == MOCK_ETH_ADDRESS) {
            return user.balance; // ETH balance
            // check if token is actually a contract
        } else if (token.isContract()) {
            return IERC20(token).balanceOf(user);
        }
        revert("INVALID_TOKEN");
    }

    /**
     * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
     * @param users The list of users
     * @param tokens The list of tokens
     * @return And array with the concatenation of, for each user, his/her balances
     **/
    function batchBalanceOf(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](users.length * tokens.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i * tokens.length + j] = balanceOf(
                    users[i],
                    tokens[j]
                );
            }
        }

        return balances;
    }

    /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
    function getUserWalletBalances(address provider, address user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());

        address[] memory reserves = pool.getReservesList();
        address[] memory reservesWithEth = new address[](reserves.length + 1);
        for (uint256 i = 0; i < reserves.length; i++) {
            reservesWithEth[i] = reserves[i];
        }
        reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

        uint256[] memory balances = new uint256[](reservesWithEth.length);

        for (uint256 j = 0; j < reserves.length; j++) {
            DataTypes.ReserveConfigurationMap memory configuration = pool
                .getConfiguration(reservesWithEth[j]);

            (bool isActive, , , , ) = configuration.getFlags();

            if (!isActive) {
                balances[j] = 0;
                continue;
            }
            balances[j] = balanceOf(user, reservesWithEth[j]);
        }
        balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);

        return (reservesWithEth, balances);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the WETH is updated.
     * @param oldAddress The old address of the WETH
     * @param newAddress The new address of the WETH
     */
    event WETHUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the ParaSpace market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple ParaSpace markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress)
        external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Returns the address of the Wrapped ETH.
     * @return The address of the Wrapped ETH
     */
    function getWETH() external view returns (address);

    /**
     * @notice Returns the info of the marketplace.
     * @return The info of the marketplace
     */
    function getMarketplace(bytes32 id)
        external
        view
        returns (DataTypes.Marketplace memory);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;

    /**
     * @notice Updates the address of the WETH.
     * @param newWETH The address of the new WETH
     **/
    function setWETH(address newWETH) external;

    /**
     * @notice Updates the info of the marketplace.
     * @param marketplace The address of the marketplace
     *  @param adapter The contract which handles marketplace logic
     * @param operator The contract which operates users' tokens
     **/
    function setMarketplace(
        bytes32 id,
        address marketplace,
        address adapter,
        address operator
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the xTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on withdrawERC721()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param tokenIds The tokenIds to be withdrawn
     **/
    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param usePTokens True if the repayment is done using xTokens, `false` if done with underlying asset directly
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );

    event BuyWithCredit(
        bytes32 indexed marketplaceId,
        DataTypes.OrderInfo orderInfo,
        DataTypes.Credit credit
    );

    event AcceptBidWithCredit(
        bytes32 indexed marketplaceId,
        DataTypes.OrderInfo orderInfo,
        DataTypes.Credit credit
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receivePToken
    );

    /**
     * @dev Emitted when a borrower's ERC721 asset is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralTokenId The token id of ERC721 asset received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral NTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event ERC721LiquidationCall(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed user,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralTokenId,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted xTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Emitted on flashClaim
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash claim
     * @param nftAsset address of the underlying asset of NFT
     * @param tokenId The token id of the asset being flash borrowed
     **/
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    /**
     * @dev Allows smart contracts to access the tokens within one transaction, as long as the tokens taken is returned.
     *
     * Requirements:
     *  - `nftTokenIds` must exist.
     *
     * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashClaimReceiver interface
     * @param nftAsset address of the underlying asset of NFT
     * @param nftTokenIds token ids of the underlying asset
     * @param params Variadic packed params to pass to the receiver as extra information
     */
    function flashClaim(
        address receiverAddress,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying xTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 pUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supplies multiple `tokenIds` of underlying ERC721 asset into the reserve, receiving in return overlying nTokens.
     * - E.g. User supplies 2 BAYC and gets in return 2 nBAYC
     * @param asset The address of the underlying asset to supply
     * @param tokenData The list of tokenIds and their collateral configs to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Same as `supplyERC721` but this can only be called by NToken contract and doesn't require sending the underlying asset.
     * @param asset The address of the underlying asset to supply
     * @param tokenData The list of tokenIds and their collateral configs to be supplied
     * @param onBehalfOf The address that will receive the xTokens
     **/
    function supplyERC721FromNToken(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent xTokens owned
     * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Withdraws multiple `tokenIds` of underlying ERC721  asset from the reserve, burning the equivalent nTokens owned
     * E.g. User has 2 nBAYC, calls withdraw() and receives 2 BAYC, burning the 2 nBAYC
     * @param asset The address of the underlying asset to withdraw
     * @param tokenIds The underlying tokenIds to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve xTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 pUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual xToken dust balance, if the user xToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithPTokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    function buyWithCredit(
        bytes32 marketplaceId,
        bytes calldata data,
        DataTypes.Credit calldata credit,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function acceptBidWithCredit(
        bytes32 marketplaceId,
        bytes calldata data,
        DataTypes.Credit calldata credit,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied ERC721 asset with a tokenID as collateral
     * @param asset The address of the underlying asset supplied
     * @param tokenId the id of the supplied ERC721 token
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseERC721AsCollateral(
        address asset,
        uint256 tokenId,
        bool useAsCollateral
    ) external virtual;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receivePToken
    ) external;

    function liquidationERC721(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an xToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param xTokenAddress The address of the xToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        DataTypes.AssetType assetType,
        address xTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an xToken transfer
     * @dev Only callable by the overlying xToken of the `asset`
     * @param asset The address of the underlying asset of the xToken
     * @param from The user from which the xTokens are transferred
     * @param to The user receiving the xTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The xToken balance of the `from` user before the transfer
     * @param balanceToBefore The xToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of xTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from "../../openzeppelin/contracts/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
    uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
    /// @dev bit 63 reserved

    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
    uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
    uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
    uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
    uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

    uint256 public constant DEBT_CEILING_DECIMALS = 2;
    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     **/
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(
            threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
            Errors.INVALID_LIQ_THRESHOLD
        );

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
            LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 bonus
    ) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data =
            (self.data & LIQUIDATION_BONUS_MASK) |
            (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~LIQUIDATION_BONUS_MASK) >>
            LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     **/
    function setDecimals(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 decimals
    ) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data =
            (self.data & DECIMALS_MASK) |
            (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(
        DataTypes.ReserveConfigurationMap memory self,
        bool frozen
    ) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     **/
    function setPaused(
        DataTypes.ReserveConfigurationMap memory self,
        bool paused
    ) internal pure {
        self.data =
            (self.data & PAUSED_MASK) |
            (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     **/
    function getPaused(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Sets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @param siloed True if the asset is siloed
     **/
    function setSiloedBorrowing(
        DataTypes.ReserveConfigurationMap memory self,
        bool siloed
    ) internal pure {
        self.data =
            (self.data & SILOED_BORROWING_MASK) |
            (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
    }

    /**
     * @notice Gets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @return The siloed borrowing flag
     **/
    function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~SILOED_BORROWING_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) <<
                STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (bool) {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveFactor
    ) internal pure {
        require(
            reserveFactor <= MAX_VALID_RESERVE_FACTOR,
            Errors.INVALID_RESERVE_FACTOR
        );

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~RESERVE_FACTOR_MASK) >>
            RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     **/
    function setBorrowCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 borrowCap
    ) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data =
            (self.data & BORROW_CAP_MASK) |
            (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     **/
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     **/
    function setSupplyCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 supplyCap
    ) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data =
            (self.data & SUPPLY_CAP_MASK) |
            (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     **/
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     **/
    function setLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 liquidationProtocolFee
    ) internal pure {
        require(
            liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
            Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
        );

        self.data =
            (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
            (liquidationProtocolFee <<
                LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     **/
    function getLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
            LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing stableRateBorrowing enabled
     * @return The state flag representing paused
     **/
    function getFlags(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~STABLE_BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     **/
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
                LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
                LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >>
                RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     **/
    function getCaps(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {OfferItem, ConsiderationItem} from "../../../dependencies/seaport/contracts/lib/ConsiderationStructs.sol";

library DataTypes {
    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        // the asset type of the reserve (uint8)
        AssetType assetType;
        //xToken address
        address xTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct ERC721SupplyParams {
        uint256 tokenId;
        bool useAsCollateral;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        AssetType assetType;
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address xTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    // struct ExecuteLiquidationCallParams {
    //     uint256 reservesCount;
    //     uint256 debtToCover;
    //     address collateralAsset;
    //     address debtAsset;
    //     address user;
    //     bool receivePToken;
    //     address priceOracle;
    //     address priceOracleSentinel;
    // }

    // struct ExecuteERC721LiquidationCallParams {
    //     uint256 reservesCount;
    //     uint256 liquidationAmount;
    //     uint256 collateralTokenId;
    //     address collateralAsset;
    //     address liquidationAsset;
    //     address user;
    //     bool receiveNToken;
    //     address priceOracle;
    //     address priceOracleSentinel;
    // }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 liquidationAmount;
        uint256 collateralTokenId;
        address collateralAsset;
        address liquidationAsset;
        address user;
        bool receiveXToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC721Params {
        address asset;
        DataTypes.ERC721SupplyParams[] tokenData;
        address onBehalfOf;
        address actualSpender;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool usePTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC721Params {
        address asset;
        uint256[] tokenIds;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        bool usedAsCollateral;
        uint256 value;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
        AssetType assetType;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
        AssetType assetType;
    }

    struct ValidateERC721LiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        uint256 tokenId;
        uint256 collateralDiscountedPrice;
        uint256 liquidationAmount;
        address priceOracleSentinel;
        address xTokenAddress;
        AssetType assetType;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address xToken;
    }

    struct InitReserveParams {
        address asset;
        AssetType assetType;
        address xTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct ExecuteFlashClaimParams {
        address receiverAddress;
        address nftAsset;
        uint256[] nftTokenIds;
        bytes params;
    }

    struct UinswapV3PositionData {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 priceA;
        uint256 priceB;
        uint256 tokenADecimal;
        uint256 tokenBDecimal;
        uint256 amountA;
        uint256 amountB;
    }

    struct Credit {
        address token;
        uint256 amount;
        bytes orderId;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ExecuteMarketplaceParams {
        bytes32 marketplaceId;
        DataTypes.Marketplace marketplace;
        bytes data;
        address WETH;
        Credit credit;
        OrderInfo orderInfo;
        uint16 referralCode;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct OrderInfo {
        address maker;
        address taker;
        bytes id;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
    }

    struct Marketplace {
        address marketplace;
        address adapter;
        address operator;
        bool paused;
    }

    function hash(Credit memory credit) external pure returns (bytes32) {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                "Credit(address token,uint256 amount,bytes orderId)"
            )
        );

        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodedata
        return
            keccak256(
                abi.encode(
                    typeHash,
                    credit.token,
                    credit.amount,
                    keccak256(abi.encodePacked(credit.orderId))
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the ParaSpace protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant CALLER_NOT_BRIDGE = "6"; // 'The caller of the function is not a bridge'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_XTOKEN = "11"; // 'The caller of the function is not an PToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant STABLE_BORROWING_NOT_ENABLED = "31"; // 'Stable borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "38"; // 'The requested amount is greater than the max loan size in stable rate mode'
    string public constant NO_DEBT_OF_SELECTED_TYPE = "39"; // 'For repayment of a specific type of debt, the user needs to have debt that type'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_STABLE_DEBT = "41"; // 'User does not have outstanding stable rate debt on this reserve'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant SAME_BLOCK_BORROW_REPAY = "48"; // 'Borrow and repay in same block is not allowed'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant XTOKEN_SUPPLY_NOT_ZERO = "54"; // 'PToken supply is not zero'
    string public constant STABLE_DEBT_NOT_ZERO = "55"; // 'Stable debt supply is not zero'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = "84"; // 'Invalid optimal stable to total debt ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant STABLE_BORROWING_ENABLED = "88"; // 'Stable borrowing is enabled'
    string public constant SILOED_BORROWING_VIOLATION = "89"; // 'User is trying to borrow multiple assets including a siloed one'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant NOT_THE_OWNER = "91"; // user is not the owner of a given asset
    string public constant LIQUIDATION_AMOUNT_NOT_ENOUGH = "92";
    string public constant INVALID_ASSET_TYPE = "93"; // invalid asset type for action.
    string public constant INVALID_FLASH_CLAIM_RECEIVER = "94"; // invalid flash claim receiver.
    string public constant ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "95"; // 'ERC721 Health factor is not below the threshold. Can only liquidate ERC20'
    string public constant UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED = "96"; //underlying asset can not be transferred.
    string public constant TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS = "97"; //token transferred can not be self address.
    string public constant INVALID_AIRDROP_CONTRACT_ADDRESS = "98"; //invalid airdrop contract address.
    string public constant INVALID_AIRDROP_PARAMETERS = "99"; //invalid airdrop parameters.
    string public constant CALL_AIRDROP_METHOD_FAILED = "100"; //call airdrop method failed.
    string public constant SUPPLIER_NOT_NTOKEN = "101"; //supplier is not the NToken contract
    string public constant CALL_MARKETPLACE_FAILED = "102"; //call marketplace failed.
    string public constant INVALID_MARKETPLACE_ID = "103"; //invalid marketplace id.
    string public constant INVALID_MARKETPLACE_ORDER = "104"; //invalid marketplace id.
    string public constant CREDIT_DOES_NOT_MATCH_ORDER = "105"; //credit doesn't match order.
    string public constant CREDIT_NOT_USED = "106"; //credit amount cannot be zero.
    string public constant PAYNOW_NOT_ENOUGH = "107"; //paynow not enough.
    string public constant INVALID_CREDIT_SIGNATURE = "108"; //invalid credit signature.
    string public constant INVALID_ORDER_TAKER = "109"; //invalid order taker.
}