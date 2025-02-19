// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./coreInterfaces/IOracle.sol";
import "./coreInterfaces/IZNft.sol";
import "./coreInterfaces/IZBond.sol";
import "./coreInterfaces/IComptroller.sol";
import "./coreInterfaces/IAuctionMarket.sol";

contract Comptroller is Initializable, UUPSUpgradeable, OwnableUpgradeable, IComptroller {
    // @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    function initialize() public initializer {
        __Ownable_init();
    }

    /******************
     * VIEW FUNCTIONS *
     ******************/

    // @notice Checks if the account should be allowed to mint tokens in the given market
    // @param  ZBond  The market to verify the mint against
    // @param  minter The account which would get the minted tokens
    // @param  mintAmount  The amount of underlying being supplied to the market in exchange for tokens
    function mintAllowed(
        address ZBond,
        address minter,
        uint256 mintAmount
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[ZBond], "Comptroller: mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;
        require(markets[ZBond].isListed, "Comptroller: market is not listed");
    }

    // @notice Checks if the account should be allowed to redeem ZNft tokens
    // @param  ZNft  The market to verify the redeem against
    // @param  redeemer  The account which would redeem the tokens
    // @param  redeemTokens  The number of ZNft tokens to exchange for the underlying asset in the market
    function redeemAllowed(
        address ZNft,
        address redeemer,
        uint256 redeemTokens
    ) external view override {
        redeemAllowedInternal(ZNft, redeemer, redeemTokens);
    }

    // @notice Checks if the account should be allowed to borrow the underlying asset of the given market
    // @param  ZBond  The market to verify the borrow against
    // @param  borrower  The account which would borrow the asset
    // @param  borrowAmount  The amount of underlying the account would borrow
    function borrowAllowed(
        address ZBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[ZBond], "Comptroller: borrow is paused");
        require(duration < IZBond(ZBond).maximumLoanDuration(), "Comptroller: borrow term too long");

        // require the caller of this function to be supported ZBond
        require(markets[address(ZBond)].isListed, "Comptroller: market is not listed");

        // total borrow has to be lower than the reserved pool.
        require(
            borrowAmount <= IERC20(IZBond(ZBond).underlying()).balanceOf(address(IZBond(ZBond).provisioningPool())) - IZBond(ZBond).totalBorrows(),
            "Comptroller: cannot borrow more than the provisioning pool"
        );
        require(IOracle(oracle).getUnderlyingPrice(ZBond) != 0, "Comptroller: asset price == 0");

        uint256 borrowCap = borrowCaps[ZBond];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = IZBond(ZBond).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(nextTotalBorrows < borrowCap, "Comptroller: market borrow cap reached");
        }

        address correspondingZNftAddress = address(IZBond(ZBond).ZNft());
        (, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(borrower, ZBond, correspondingZNftAddress, 0, borrowAmount);
        require(shortfall == 0, "Comptroller: insufficient liquidity to borrow");
    }

    // @notice Checks if the initiator should be allowed to borrow on behalf of some account
    // @param  ZBond  The market to borrow on behalf from
    // @param  initiator  The initiator that intends to borrow on behalf of someone
    function borrowOnBehalfAllowed(address ZBond, address initiator) external view override {
        ZBond;
        require(initiator == bnpl, "Comptroller: only bnpl contract is allowed to borrow on behalf");
    }

    // @notice Checks if the account should be allowed to repay a borrow in the given market
    // @param  ZBond  The market to verify the repay against
    // @param  payer  The account which would repay the asset
    // @param  borrower  The account which would borrowed the asset
    // @param  repayAmount  The amount of the underlying asset the account would repay
    function repayBorrowAllowed(
        address ZBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external view override {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        require(markets[address(ZBond)].isListed, "Comptroller: market is not listed.");
        require(IZBond(ZBond).getAccountCurrentBorrowBalance(borrower) > 0, "Comptroller: no outstanding balance");
    }

    // @notice Checks if the liquidation should be allowed to occur
    // @param  ZBondBorrowed  Asset which was borrowed by the borrower
    // @param  ZNft  Asset which was used as collateral and will be seized
    // @param  liquidator  The address repaying the borrow and seizing the collateral
    // @param  borrower  The address of the borrower
    // @param  tokenId  The ZNft tokenId used as collateral
    function liquidateBorrowAllowed(
        address ZBondBorrowed,
        address ZNft,
        address liquidator,
        address borrower,
        uint256 tokenId
    ) external view override {
        // Shh - currently unused
        // TODO: @zilinma. are we allowing people to call liquidateBorrow when the borrow is under water?
        // this will allow anyone to seize the ZNft and repay borrow on behalf without going thru the auction process
        require(address(IZBond(ZBondBorrowed).provisioningPool()) == liquidator, "Comptroller: only ZBond's pp can liquidateBorrow");

        require(markets[ZBondBorrowed].isListed, "Comptroller: ZBond market not listed");
        require(liquidator != borrower, "Comptroller: Cannot liquidate self");
        require(IZNft(ZNft).ownerOf(tokenId) == borrower, "Comptroller: Cannot liquidate NFT that the borrower do not own.");
        (, uint256 shortfall) = getAccountLiquidityInternal(borrower, ZNft);
        BorrowSnapshot memory borrowSnapshot;
        (borrowSnapshot.deadline, borrowSnapshot.loanDuration, borrowSnapshot.minimumPaymentDue, borrowSnapshot.principalBorrow, borrowSnapshot.weightedInterestRate) = IZBond(ZBondBorrowed)
            .accountBorrows(borrower);
        require(
            (shortfall > 0) ||
                (borrowSnapshot.minimumPaymentDue < block.timestamp && borrowSnapshot.minimumPaymentDue != 0) ||
                (borrowSnapshot.deadline < block.timestamp && borrowSnapshot.deadline != 0),
            "Comptroller: insufficient shortfall to liquidate or not overdue."
        );
    }

    // @notice Checks if the seizing of assets should be allowed to occur
    // @param  ZNft  Asset which was used as collateral and will be seized
    // @param  ZBondBorrowed  Asset which was borrowed by the borrower
    // @param  liquidator  The address repaying the borrow and seizing the collateral
    // @param  borrower  The address of the borrower
    // @param  seizeTokens  The number of collateral tokens to seize
    function seizeAllowed(
        address ZNft,
        address ZBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "Comptroller: seize is paused");

        // Shh - currently unused
        seizeTokens;
        liquidator;
        borrower;
        require(markets[ZNft].isListed, "Comptroller: ZNft collateral is not listed");
        require(markets[ZBondBorrowed].isListed, "Comptroller: ZBond collateral is not listed");
        require(IZBond(ZBondBorrowed).provisioningPool() == liquidator, "Comptroller: only provisioningPool can be the liquidator");

        require(IZNft(ZNft).comptroller() == address(IZBond(ZBondBorrowed).comptroller()), "Comptroller: comptroller mismatch");
    }

    // @notice Checks if the account should be allowed to transfer tokens in the given market
    // @param  ZNft  The market to verify the transfer against
    // @param  src  The account which sources the tokens
    // @param  dst  The account which receives the tokens
    // @param  tokenId  the tokenId to be transferred
    function transferAllowed(
        address ZNft,
        address src,
        address dst,
        uint256 tokenId
    ) external view override {
        // unused
        dst;
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "Comptroller: transfer is paused");

        (, , , , , , bool isOnAuction, ) = IAuctionMarket(auctionMarket).auctionInfo(ZNft, tokenId);
        require(isOnAuction == false, "Comptroller: ZNft is being auctioned");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        redeemAllowedInternal(ZNft, src, 1);
    }

    // @notice Calculate the liquidation amount given the ZNft token Id
    // @param  borrower  The borrower that owns the tokenId ZNft
    // @param  ZBondBorrowed  The ZBond that the borrower borrows from
    // @param  tokenId  The ZNft collateral tokenId
    // @param  ZNft  The ZNft used as collateral
    function calculateLiquidationAmount(
        address borrower,
        address ZBondBorrowed,
        uint256 tokenId,
        address ZNft
    ) external view override returns (uint256) {
        // calculate the credit offered by one NFT
        // numNFTs * price * collateralRate
        require(IZNft(ZNft).ownerOf(tokenId) == borrower, "Comptroller: borrower is not ZNft tokenId holder");
        uint256 nftPriceMantissa = IOracle(oracle).getUnderlyingPrice(ZNft);
        require(nftPriceMantissa > 0, "Comptroller: asset price == 0");

        uint256 nftCollateralFactor = markets[address(ZNft)].collateralFactorMantissa;
        uint256 maxRepay = (nftCollateralFactor * nftPriceMantissa) / 1e18;

        // calculate the borrowed balance equivalent value
        uint256 borrowBalance = IZBond(ZBondBorrowed).getAccountCurrentBorrowBalance(borrower);
        uint256 borrowedAssetPriceMantissa = IOracle(oracle).getUnderlyingPrice(ZBondBorrowed);
        uint256 borrowValue = (borrowBalance * borrowedAssetPriceMantissa) / 1e18;
        if (maxRepay > borrowValue) {
            // if borrowed asset is less expensive than the NFT, can liquidate all borrow balance
            return borrowBalance;
        } else {
            // if borrowed assets is more expensive than the NFT, can only liquidate the collateral value of NFT
            return (maxRepay * 1e18) / borrowedAssetPriceMantissa;
        }
    }

    // @notice Check if a market is listed
    // @param  market  The market contract address to check
    // @return A boolean indicating whether the market is listed
    function isListedMarket(address market) external view override returns (bool) {
        return markets[market].isListed;
    }

    // @notice Determine the current account liquidity wrt collateral requirements
    // @param  account  The account of which liquidity is calculated
    // @param  ZNft  The ZNft collateral pool on which the liquidity is calculated based
    // @return (possible error code (semi-opaque),
    //          account liquidity in excess of collateral requirements,
    //          account shortfall below collateral requirements)
    function getAccountLiquidity(address account, address ZNft) public view override returns (uint256, uint256) {
        (uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(account, address(0), ZNft, 0, 0);

        return (liquidity, shortfall);
    }

    // @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
    //         Note that we calculate the currentBorrowBalance including the accrued interest as of the current block
    // @param  assetModify  The market to hypothetically redeem/borrow in
    // @param  account  The account to determine liquidity for
    // @param  redeemTokens  The number of tokens to hypothetically redeem
    // @param  borrowAmount  The amount of underlying to hypothetically borrow
    // @return (possible error code (semi-opaque),
    //          hypothetical account liquidity in excess of collateral requirements,
    //          hypothetical account shortfall below collateral requirements)
    function getHypotheticalAccountLiquidity(
        address account,
        address assetModify,
        address ZNft,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {
        (uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(account, assetModify, ZNft, redeemTokens, borrowAmount);
        return (liquidity, shortfall);
    }

    // @notice Returns true if the given ZBond market has been deprecated
    //         All borrows in a deprecated ZBond market can be immediately liquidated
    // @param  ZBond  The market to check if deprecated
    // @return A boolean indicating whether the ZBond is deprecated
    function isDeprecated(address ZBond) public view returns (bool) {
        return markets[ZBond].collateralFactorMantissa == 0 && borrowGuardianPaused[ZBond] == true;
    }

    /**********************
     * INTERNAL FUNCTIONS *
     **********************/
    function redeemAllowedInternal(
        address asset,
        address redeemer,
        uint256 redeemTokens
    ) internal view {
        require(markets[asset].isListed, "Comptroller: market is not listed");
        (, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, asset, asset, redeemTokens, 0);
        require(shortfall == 0, "Comptroller: insufficient liquidity to redeem");
    }

    // @notice Determine the current account liquidity wrt collateral requirements
    // @param  account  The account of which liquidity is calculated
    // @param  ZNft  The ZNft collateral pool on which the liquidity is calculated based
    // @return (possible error code,
    //          account liquidity in excess of collateral requirements,
    //          account shortfall below collateral requirements)
    function getAccountLiquidityInternal(address account, address ZNft) internal view returns (uint256, uint256) {
        return getHypotheticalAccountLiquidityInternal(account, address(0), ZNft, 0, 0);
    }

    // @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
    // @param  assetModify  The market to hypothetically redeem/borrow in
    // @param  account  The account to determine liquidity for
    // @param  redeemNFTAmount  The amount of underlying to hypothetically borrow
    // @param  borrowAmount  The amount of underlying to hypothetically borrow
    // @return (possible error code,
    //          hypothetical account liquidity in excess of collateral requirements,
    //          hypothetical account shortfall below collateral requirements)
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address assetModify,
        address ZNft,
        uint256 redeemNFTAmount,
        uint256 borrowAmount
    ) internal view returns (uint256, uint256) {
        require(address(oracle) != address(0), "Comptroller: oracle not set");
        require(address(nftOracle) != address(0), "Comptroller: nft oracle not set");

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        if ((assetModify != ZNft) && assetModify != address(0)) {
            require(allMarkets[ZNft] == assetModify, "Comptroller: markets mismatch");
        }

        // For each ZBond the ZNft corresponds to
        IZBond asset = IZBond(IZNft(ZNft).ZBond());

        // Read the balances from the ZBond
        vars.borrowBalance = asset.getAccountCurrentBorrowBalance(account);

        // Get the normalized price of the asset
        vars.oraclePriceMantissa = IOracle(oracle).getUnderlyingPrice(address(asset));
        require(vars.oraclePriceMantissa != 0, "Comptroller: ZBond price is not set.");

        // sumBorrowPlusEffects += oraclePrice * borrowBalance
        vars.sumBorrowPlusEffects += (vars.oraclePriceMantissa * vars.borrowBalance) / 1e18;

        // Calculate effects of interacting with ZBondModify
        if (address(asset) == assetModify) {
            // borrow effect
            // sumBorrowPlusEffects += oraclePrice * borrowAmount
            vars.sumBorrowPlusEffects += (vars.oraclePriceMantissa * borrowAmount) / 1e18;
        }

        // calculate ZNft collateral value with or without changes
        uint256 nftBalance = IZNft(ZNft).balanceOf(account);

        if (nftBalance > 0) {
            // Get the price of the NFT and the collateral factor
            vars.nftOraclePriceMantissa = IOracle(nftOracle).getUnderlyingPrice(ZNft);
            require(vars.nftOraclePriceMantissa != 0, "Comptroller: NFT price cannot be 0.");
            // sumCollateral += nftOraclePrice * collateralFactor * nftBalance
            vars.sumCollateral = (vars.nftOraclePriceMantissa * markets[address(ZNft)].collateralFactorMantissa * nftBalance) / 1e18;
        }
        // should revert if attempted redeemNFTAmount is more than the ZNft the user holds
        if (assetModify == address(ZNft)) {
            vars.sumCollateral -= (vars.nftOraclePriceMantissa * markets[address(ZNft)].collateralFactorMantissa * redeemNFTAmount) / 1e18;
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /*******************
     * ADMIN FUNCTIONS *
     *******************/

    // @notice Sets a new price oracle for the comptroller
    // @param  newOracle   New oracle contract
    function _setPriceOracle(address newOracle) public onlyOwner {
        // Track the old oracle for the comptroller
        address oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);
    }

    // @notice Sets a new price oracle for the comptroller
    // @param  newOracle  New oracle contract
    function _setNftPriceOracle(address newOracle) public onlyOwner {
        // Track the old oracle for the comptroller
        address oldOracle = nftOracle;
        // Set comptroller's nft oracle to newOracle
        nftOracle = newOracle;

        emit NewNFTPriceOracle(oldOracle, newOracle);
    }

    // @notice Sets a new auction market
    // @param  newAuctionMarket  New auction market
    function _setAuctionMarket(address newAuctionMarket) public onlyOwner {
        address oldAuctionMarket = auctionMarket;
        auctionMarket = newAuctionMarket;
        emit NewAuctionMarket(oldAuctionMarket, newAuctionMarket);
    }

    // @notice Sets a new bnpl
    // @param  newBnpl  New bnpl contract
    function _setBnpl(address newBnpl) public onlyOwner {
        address oldBnpl = bnpl;
        bnpl = newBnpl;
        emit NewBNPL(oldBnpl, newBnpl);
    }

    // @notice Sets a borrowCap for a ZBond market
    // @param  ZBondAddress  The ZBond market of which borrowCap is to be changed
    // @param  newBorrowCap  BorrowCap enforced on a ZBond market
    function _setBorrowCap(address ZBondAddress, uint256 newBorrowCap) external {
        require(msg.sender == borrowCapGuardian || msg.sender == owner(), "Comptroller: only borrowCapGuardian and owner can set borrow cap");
        borrowCaps[ZBondAddress] = newBorrowCap;
    }

    // @notice Sets the collateralFactor for a market; Owner function to set per-market collateralFactor
    // @param  ZNft  The market to set the factor on
    // @param  newCollateralFactorMantissa  The new collateral factor, scaled by 1e18
    function _setCollateralFactor(address ZNft, uint256 newCollateralFactorMantissa) external onlyOwner {
        //  verify the market is NFT
        Market storage market = markets[address(ZNft)];
        require(IZNft(ZNft).isZNft(), "Comptroller: NFTs collaterals only");

        // Verify market is listed
        require(market.isListed, "Comptroller: Cannot set non-exisiting market collateral factors.");

        // Check collateral factor <= 0.9
        require(collateralFactorMaxMantissa >= newCollateralFactorMantissa, "Comptroller: Collateral factor too large.");
        // If collateral factor != 0, fail if price == 0

        require(IOracle(nftOracle).getUnderlyingPrice(ZNft) != 0, "Comptroller: ZNft underlying price is 0");

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(ZNft, oldCollateralFactorMantissa, newCollateralFactorMantissa);
    }

    // @notice Add the market to the markets mapping and set it as listed;Owner function to set isListed and add support for the market
    // @param  ZBond  The address of the market (token) to list
    // @param  ZNft  The address of the market (token) to list
    function _supportMarket(address ZNft, address ZBond) external onlyOwner {
        require(IZNft(ZNft).isZNft(), "Comptroller: ZNft is not an NFT");
        require(IZBond(ZBond).isZBond(), "Comptroller: ZBond is not a ZBond");
        require(!markets[ZBond].isListed, "Comptroller: ZBond already listed");
        require(IZBond(ZBond).ZNft() == ZNft, "Comptroller: ZBond ZNft do not match");

        markets[ZBond].isListed = true;
        markets[ZNft].isListed = true;
        nftToZNft[IZNft(ZNft).underlying()] = ZNft;
        allMarkets[ZNft] = ZBond;
        IZNft(ZNft).setZBond(ZBond);
        emit MarketListed(ZNft, ZBond);
    }

    // @notice Owner function to change the Pause Guardian
    // @param  newPauseGuardian  The address of the new Pause Guardian
    function _setPauseGuardian(address newPauseGuardian) public onlyOwner {
        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
    }

    // @notice Owner function to change the borrowCapGuardian address
    // @param  newBorrowCapGuardian  The new borrowCapGuardian address
    function _setBorrowCapGuardian(address newBorrowCapGuardian) public onlyOwner {
        borrowCapGuardian = newBorrowCapGuardian;
    }

    // @notice Owner function to change the mintPause state of a market
    // @param  asset  The market to set the mint pause state for
    // @param  state  The state of mintPaused set for the market
    function _setMintPaused(address asset, bool state) public returns (bool) {
        require(markets[asset].isListed, "Comptroller: cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == owner(), "Comptroller: only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "Comptroller: only owner can unpause");

        mintGuardianPaused[asset] = state;

        emit MarketActionPaused(asset, "Mint", state);

        return state;
    }

    // @notice Owner function to change the borrowPaused state of a market
    // @param  ZBond  The market to set the borrowPaused state for
    // @param  state  The state of borrowPaused set for the market
    function _setBorrowPaused(address ZBond, bool state) public {
        require(markets[ZBond].isListed, "Comptroller: cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == owner(), "Comptroller: only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "Comptroller: only owner can unpause");

        borrowGuardianPaused[ZBond] = state;
        emit MarketActionPaused(ZBond, "Borrow", state);
    }

    // @notice Owner function to change the transferPaused state for the protocol
    // @param  state  The state of transferPaused set for the protocol
    function _setTransferPaused(bool state) public {
        require(msg.sender == pauseGuardian || msg.sender == owner(), "Comptroller: only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "Comptroller: only owner can unpause");

        transferGuardianPaused = state;
        emit GlobalActionPaused("Transfer", state);
    }

    // @notice set the seize pause state for the whole protocol
    // @param state The state that is set for pausing the 'seize' function
    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == owner(), "Comptroller: only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "Comptroller: only owner can unpause");

        seizeGuardianPaused = state;
        emit GlobalActionPaused("Seize", state);
        return state;
    }

    /*******************
     * PROXY FUNCTIONS *
     *******************/

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./coreInterfaces/IFeeSelector.sol";

contract FeeSelector is IFeeSelector {
    constructor(
        IERC20 _decisionToken,
        uint256 _upperBoundLong,
        uint256 _lowerBoundLong,
        uint256 _upperBoundShort,
        uint256 _lowerBoundShort
    ) {
        decisionToken = _decisionToken;
        longPool.upperBound = _upperBoundLong;
        longPool.lowerBound = _lowerBoundLong;

        shortPool.upperBound = _upperBoundShort;
        shortPool.lowerBound = _lowerBoundShort;
    }

    // @notice A user can call this address to cast their vote on the interest rates used by the protocol
    // @param  upperAmount  The amount of decisionToken casted to vote for the upper bound of the term of the interest rate
    // @param  lowerAmount  The amount of decisionToken casted to vote for the lower bound of the term of the interest rate
    // @param  isLong  Whether this vote is for the long term interest rate or short term interest rate
    function stake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong += upperAmount;
            userAcounts[msg.sender].lowerLong += lowerAmount;

            longPool.upperTotal += upperAmount;
            longPool.lowerTotal += lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort += upperAmount;
            userAcounts[msg.sender].lowerShort += lowerAmount;

            shortPool.upperTotal += upperAmount;
            shortPool.lowerTotal += lowerAmount;
        }

        decisionToken.transferFrom(msg.sender, address(this), upperAmount + lowerAmount);
    }

    // @notice A user can call this address to unstake the decisionToken from this contract and remove the casted votes
    // @param  upperAmount  The amount of decisionToken casted to vote for the upper bound of the term of the interest rate
    // @param  lowerAmount  The amount of decisionToken casted to vote for the lower bound of the term of the interest rate
    // @param  isLong  Whether this vote is for the long term interest rate or short term interest rate
    function unstake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong -= upperAmount;
            userAcounts[msg.sender].lowerLong -= lowerAmount;

            longPool.upperTotal -= upperAmount;
            longPool.lowerTotal -= lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort -= upperAmount;
            userAcounts[msg.sender].lowerShort -= lowerAmount;

            shortPool.upperTotal -= upperAmount;
            shortPool.lowerTotal -= lowerAmount;
        }

        decisionToken.transfer(msg.sender, upperAmount + lowerAmount);
    }

    // @notice This function calculates the funding cost for a specified duration
    // @dev  Rate calculation formula:shortRate + (loanDuration) * (longRate - shortRate)/ (maximumLoanDuration)
    // @param  loanDuration  The duration of the loan
    // @param  maximumLoanDuration The maximum duration of the loan
    // @return The interest rate for the loanDuration
    function getFundingCostForDuration(uint256 loanDuration, uint256 maximumLoanDuration) external view override returns (uint256) {
        require(loanDuration <= maximumLoanDuration, "FeeSelector: loanDuration should be lt or eq to maximumLoanDuration");
        (uint256 longRate, uint256 shortRate) = getFundingCostRateFx();
        return ((longRate - shortRate) * loanDuration) / maximumLoanDuration + shortRate;
    }

    // @notice This function calculates the funding cost for a given term based on casted votes
    // @param  pool  The specified term of which the rate is being calculated
    // @return The interest rate for the term
    function getFundingCost(PoolInfo memory pool) public pure returns (uint256) {
        if (pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return (pool.upperBound * pool.upperTotal + pool.lowerBound * pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    // @notice This function calculates the funding cost for the short duration and the long duration
    // @return The interest rate for the both short term and long term
    function getFundingCostRateFx() public view returns (uint256, uint256) {
        uint256 longTermRate = getFundingCost(longPool);
        uint256 shortTermRate = getFundingCost(shortPool);
        return (longTermRate, shortTermRate);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./coreInterfaces/IZNft.sol";
import "./coreInterfaces/IComptroller.sol";

contract ZNft is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard, IZNft {
    modifier validReceive(address operator) {
        require(msg.sender == underlying, "ZNft: This contract can only receive the underlying NFT");
        require(operator == address(this), "ZNft: only the ZNft contract can be the operator");
        _;
    }

    function initialize(
        string memory _uri,
        address _underlying,
        address _comptroller,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        underlying = _underlying;
        comptroller = _comptroller;
        uri = _uri;
        isZNft = true;
    }

    /******************
     * VIEW FUNCTIONS *
     ******************/

    // @notice Gets the provisioningPool associated with the ZBond associated with this ZNft
    // @return The provisoningPool
    function provisioningPool() public view override returns (address) {
        return IZBond(ZBond).provisioningPool();
    }

    /**********************
     * EXTERNAL FUNCTIONS *
     **********************/

    // @notice A caller can mint multiple ZNfts by pledging underlying Nfts
    // @param  tokenIds  The underlying NFT's tokenIds that the caller would like to deposit
    // @param  receiver  The receiver that will receive the minted ZNft
    function mint(uint256[] calldata tokenIds, address receiver) external override nonReentrant {
        // Check if the Comptroller allows minting.
        // We set mintAmount to 0 because it is not used.
        IComptroller(comptroller).mintAllowed(address(this), msg.sender, 0);

        uint256 length = tokenIds.length;
        require(length != 0, "ZNft: cannot mint 0 nft");
        for (uint256 i; i < length; ++i) {
            IERC721(underlying).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        for (uint256 i = 0; i < length; i++) {
            _mint(receiver, tokenIds[i]);
        }
        emit Mint(receiver, tokenIds);
    }

    // @notice A caller can redeem multiple ZNfts for the underlying Nfts deposited
    // @param  tokenIds  The ZNft's tokenIds that the caller would like to redeem
    // @param  receiver  The receiver that will receive the underlying Nfts
    function redeem(uint256[] calldata tokenIds, address receiver) external override nonReentrant {
        uint256 length = tokenIds.length;

        // Check for ownership.
        for (uint256 i; i < length; ++i) {
            require(ownerOf(tokenIds[i]) == msg.sender, "ZNft: does not own redeem");
        }

        // Check if we can redeem.
        IComptroller(comptroller).redeemAllowed(address(this), msg.sender, length);

        // Burn ZNfts.
        for (uint256 j; j < length; j++) {
            _burn(tokenIds[j]);
        }

        // Transfer underlying to `to`.
        for (uint256 i; i < length; ++i) {
            IERC721(underlying).safeTransferFrom(address(this), receiver, tokenIds[i]);
        }
        emit Redeem(receiver, tokenIds);
    }

    // @notice A liquidator can seize the ZNft, ignoring the transferAllowed limitation imposed on ZNfts pledged for an under-the-water loan
    //         This function should only be called by ZBond
    // @param  liquidator  The liquidator that will receive the seized ZNft, should always be the provisioningPool
    // @param  borrower  The borrower whose ZNft is being seized
    function seize(
        address liquidator,
        address borrower,
        uint256 tokenId
    ) external override nonReentrant {
        // Check if the Comptroller allows seizing.
        // We set seizeAmount to 0 because it is not used.
        IComptroller(comptroller).seizeAllowed(address(this), msg.sender, liquidator, borrower, 0);

        // Fail if borrower == liquidator.
        require(borrower != liquidator, "ZNft: liquidator cannot be borrower");

        // Transfer ZNft.

        // We call the internal function instad of the public one because in liquidation, we
        // forcibly seize the borrower's ZNfts without approval.
        _transfer(borrower, liquidator, tokenId);
    }

    // @notice A caller can batch transfer multiple ZNfts
    // @param  from  The ZNft will be transferred from
    // @param  to  The ZNft will be transferred to
    // @param  tokenIds  The tokenIds that will be transferred
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external override nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; i++) {
            // calling our implemented safeTransferFrom
            safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    // @notice A caller can transfer a ZNft, note that if the borrower current has debt and the zNft is pledged for the loan
    //         IComptroller(comptroller).transferAllowed will revert
    // @dev    OpenZeppelin's safeTransferFrom(address,address,uint256) calls this function with empty bytedata
    //         so instead of overriding safeTransferFrom(address,address,uint256), we should override safeTransferFrom(address,address,uint256,bytes)
    // @param  from  The ZNft will be transferred from
    // @param  to  The ZNft will be transferred to
    // @param  tokenId  The tokenId to be transferred
    // @param  data  Extra data to be passed to onERC721Received
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override(ERC721Upgradeable) {
        IComptroller(comptroller).transferAllowed(address(this), from, to, id);
        super.safeTransferFrom(from, to, id, data);
    }

    // @notice A caller can transfer a ZNft, note that if the borrower current has debt and the zNft is pledged for the loan
    //         IComptroller(comptroller).transferAllowed will revert
    // @param  from  The ZNft will be transferred from
    // @param  to  The ZNft will be transferred to
    // @param  tokenId  The tokenId to be transferred
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721Upgradeable) {
        IComptroller(comptroller).transferAllowed(address(this), from, to, id);
        super.transferFrom(from, to, id);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override validReceive(operator) returns (bytes4) {
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }

    /*******************
     * ADMIN FUNCTIONS *
     *******************/

    function setZBond(address newZBond) public override {
        require(msg.sender == comptroller, "ZNft: only comptroller can set ZBond for ZNft");
        ZBond = newZBond;
    }

    /**********************
     * INTERNAL FUNCTIONS *
     **********************/

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    /*******************
     * PROXY FUNCTIONS *
     *******************/

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./coreInterfaces/IZBond.sol";
import "./Comptroller.sol";
import "./ZNft.sol";
import "./FeeSelector.sol";

contract ZumerLens {
    function getAccountLiquidityMultiple(
        address[] calldata znfts,
        address account,
        Comptroller comptroller
    ) public view returns (uint256 credit) {
        for (uint256 i = 0; i < znfts.length; i++) {
            (uint256 liquidity, ) = comptroller.getAccountLiquidity(account, znfts[i]);
            credit += liquidity;
        }
        return credit;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract AuctionMarketStorage {
    // @notice Event emitted when an auction starts
    event Start(address ZNft, uint256 tokenId, uint256 repayAmount, address originalOwner, uint256 endTime);
    // @notice Event emitted when a bid is submitted
    event Bid(address indexed bidder, address ZNft, uint256 tokenId, uint256 amount);
    // @notice Event emitted when an auction is concluded
    event EndAuction(address winnder, address ZNft, uint256 tokenId, uint256 closeAmount);
    // @notice Event emitted when insurance is activated
    event IncreaseInsurance(address ZNft, address account, uint256 amount);
    // @notice Event emitted when insurance is spent
    event DecreaseInsurance(address ZNft, address account, uint256 amount);
    // @notice AuctionInfo container
    struct AuctionInfo {
        // @notice The time when the borrower can no longer depay borrow debt to redeem.
        uint256 redeemEndAt;
        // @notice The time when the auction ends and the highest bid gets the NFT.
        uint256 auctionEndAt;
        // @notice Highest bidder address
        address highestBidder;
        // @notice Highest bidding value
        uint256 highestBid;
        // @notice The balance that the borrower have to repay to redeem the NFT.
        uint256 minimumBid;
        // @notice Address of the borrower who originally own the NFT.
        address borrower;
        // @notice Is auction still going
        bool isOnAuction;
        // @notice Is auction started by zNft owner
        bool isSelfListed;
    }

    // @notice Underlying token address for bidding
    address public underlying;
    // @notice Comptroller address
    address public comptroller;
    // @notice gracePeriod given to all liquidated ZNft holders so that they can pay penalty and reclaim their ZNft before auction concludes
    uint256 public gracePeriod;
    // @notice Auction duration; global
    uint256 public auctionDuration;
    // @notice Additional grace period given to insurance buyers so that they can reclaim their ZNft before auction concludes
    uint256 public insuranceGracePeriod;
    // @notice If a bid has been submitted and the ZNft is reclaimed by the original holder during the grace period, bidder will receive
    //         bidderPenaltyShareBasisPoint share of the penalty paid by the claimer
    uint256 public bidderPenaltyShareBasisPoint; // 10000 = 1%
    // @notice Penalty imposed on the zNft claimer during the grace period
    uint256 public penaltyBasisPoint; // 10000 = 1%
    // @notice Auction end time will be extended by bidExtension amount of time if a bid is submitted within T-bidExtension
    uint256 public bidExtension = 10 minutes;
    // @notice Global mapping of ZNft -> tokenId -> auctionInfo
    mapping(address => mapping(uint256 => AuctionInfo)) public auctionInfo;
    // @notice Global mapping of ZNft -> tokenId -> boolean, representing whether an insurance is purchased
    mapping(address => mapping(uint256 => bool)) public insurance;
    // @notice Global mapping of ZNft -> tokenId -> hit points of the users insurance
    mapping(address => mapping(address => uint256)) public accountInsurance;
}

abstract contract IAuctionMarket is AuctionMarketStorage {
    function startAuction(
        uint256 tokenId,
        uint256 minimumBid,
        address originalOwner,
        address ZNft
    ) external virtual;

    function bid(
        uint256 tokenId,
        address ZNft,
        uint256 amount
    ) external virtual;

    function bidOnBehalf(
        address bidder,
        uint256 tokenId,
        address ZNft,
        uint256 amount
    ) external virtual;

    function redeemAndPayPenalty(uint256 tokenId, address ZNft) external virtual;

    function winBid(address ZNft, uint256 tokenId) external virtual;

    function activateInsurance(
        address ZNftAddress,
        address originalOwner,
        uint256 amount
    ) external virtual;

    function cancelAuction(address ZNft, uint256 tokenId) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IZNft.sol";
import "./IZBond.sol";

contract ComptrollerStorage {
    // @notice Emitted when an owner supports a market
    event MarketListed(address ZNft, address ZBond);

    // @notice Emitted when a collateral factor is changed by owner
    event NewCollateralFactor(address ZNft, uint256 oldCollateralFactorMantissa, uint256 newCollateralFactorMantissa);

    // @notice Emitted when the auctionMarket is changed by owner
    event NewAuctionMarket(address oldAuctionMarket, address newAuctionMarket);

    // @notice Emitted when the bnpl is changed by owner
    event NewBNPL(address oldBnpl, address newBnpl);

    // @notice Emitted when price oracle is changed
    event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

    // @notice Emitted when price oracle is changed
    event NewNFTPriceOracle(address oldPriceOracle, address newPriceOracle);

    // @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    // @notice Emitted when an action is paused globally
    event GlobalActionPaused(string action, bool pauseState);

    // @notice Emitted when an action is paused on a market
    event MarketActionPaused(address asset, string action, bool pauseState);

    // @notice Container for borrow balance information
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInterestRate;
    }

    // @notice Local vars for avoiding stack-depth limits in calculating account liquidity.
    //         note that `borrowBalance` is the amount of underlying that the account has borrowed plus any accrued interest as of the current block
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        uint256 nftOraclePriceMantissa;
    }
    struct Market {
        // @notice Whether or not this market is listed
        bool isListed;
        // @notice Multiplier representing the most one can borrow against their collateral in this market.
        //         For instance, 0.9 to allow borrowing 90% of collateral value.
        //         Must be between 0 and 1, and stored as a mantissa.
        uint256 collateralFactorMantissa;
    }

    // @notice Auction market contract that hosts the liquidated zNft auctions
    address public auctionMarket;

    // @notice Oracle which gives the price of any given asset
    address public oracle;

    // @notice The nftOracle contract that provides the floor price of Nfts
    address public nftOracle;

    // @notice The Pause Guardian can pause certain actions as a safety mechanism.
    //         Actions which allow users to remove their own assets cannot be paused.
    //         Liquidation / seizing / transfer can only be paused globally, not by market.
    address public pauseGuardian;

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice The zumerBuyNowPayLater contract address
    address public bnpl;

    // @notice The boolean stating whether zNft transfer is paused; it is global.
    bool public transferGuardianPaused;

    // @notice The boolean stating whether zNft seize function is paused; it is global
    bool public seizeGuardianPaused;

    // @notice Mapping of contract address to Market info
    mapping(address => Market) public markets;

    // @notice Mapping of markets that have its mint function paused
    mapping(address => bool) public mintGuardianPaused;

    // @notice Mapping of markets that have its borrow function paused
    mapping(address => bool) public borrowGuardianPaused;

    // @notice Mapping of underlying Nft to zNft
    mapping(address => address) public nftToZNft;

    // @notice Mapping of ZNft to ZBond
    mapping(address => address) public allMarkets;

    // @notice Borrow caps enforced by borrowAllowed for each ZBond address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;
}

abstract contract IComptroller is ComptrollerStorage {
    function mintAllowed(
        address ZBond,
        address minter,
        uint256 mintAmount
    ) external view virtual;

    function redeemAllowed(
        address zNft,
        address redeemer,
        uint256 redeemTokens
    ) external view virtual;

    function borrowAllowed(
        address ZBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external view virtual;

    function borrowOnBehalfAllowed(address ZBond, address initiator) external view virtual;

    function repayBorrowAllowed(
        address ZBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external view virtual;

    function liquidateBorrowAllowed(
        address ZBondBorrowed,
        address ZNft,
        address liquidator,
        address borrower,
        uint256 tokenId
    ) external view virtual;

    function seizeAllowed(
        address ZBondCollateral,
        address ZBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external view virtual;

    function transferAllowed(
        address ZNft,
        address src,
        address dst,
        uint256 tokenId
    ) external view virtual;

    function calculateLiquidationAmount(
        address borrower,
        address ZBondBorrowed,
        uint256 tokenId,
        address ZNft
    ) external view virtual returns (uint256);

    function isListedMarket(address market) external view virtual returns (bool);

    function getAccountLiquidity(address account, address ZNft) public view virtual returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeSelectorStorage {
    // @notice A container that stores a user's votes toward different interest rates
    struct UserVotes {
        // @notice Upper bound of the long term interest rate
        uint256 upperLong;
        // @notice Lower bound of the long term interest rate
        uint256 lowerLong;
        // @notice Upper bound of the short term interest rate
        uint256 upperShort;
        // @notice Lower bound of the short term interest rate
        uint256 lowerShort;
    }

    // @notice A container that stores a pool level accumulated votes
    struct PoolInfo {
        // @notice Upper bound of the interest rate term
        uint256 upperBound;
        // @notice Lower bound of the interest rate term
        uint256 lowerBound;
        // @notice Total votes for the upper bound
        uint256 upperTotal;
        // @notice Total votes for the lower bound
        uint256 lowerTotal;
    }
    // @notice The ERC20 token that is used for voting
    IERC20 public decisionToken;
    // @notice The long term interest rate info
    PoolInfo public longPool;
    // @notice The short term interest rate info
    PoolInfo public shortPool;
    // @notice The global mapping of address to its accumulated votes
    mapping(address => UserVotes) public userAcounts;
}

abstract contract IFeeSelector is FeeSelectorStorage {
    function getFundingCostForDuration(uint256 loanDuration, uint256 maximumLoanDuration) external view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The asset to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address asset) external view virtual returns (uint256);

    function getInsurancePrice(address asset) external view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZBondStorage {
    // @notice Event emitted when tokens are minted
    event Mint(uint256 tokenId, uint256 mintAmount, uint256 mintTokens, uint256 totalSupply);

    // @notice Event emitted when underlying is borrowed
    event Borrow(address borrower, uint256 borrowAmount, uint256 totalBorrows, uint256 duration);

    // @notice Event emitted when a borrow is repaid
    event RepayBorrow(address payer, address borrower, uint256 repayAmount);

    // @notice Event emitted when a borrow is liquidated
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral);
    // @notice Event emitted when tokens are redeemed
    event Redeem(uint256 tokenId, uint256 redeemAmount, uint256 redeemTokens);
    // @notice Container for borrow balance information
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInterestRate;
    }

    // @notice Container for supply balance information
    struct SupplySnapshot {
        uint256 principalSupply;
        uint256 startDate;
        uint256 virtualBalance;
    }
    // @notice Fraction of interest currently set aside for reserves
    uint256 public provisioningPoolMantissa;

    // @notice Total amount of outstanding borrows of the underlying in this market
    uint256 public totalBorrows;

    // @notice Total number of underlying accumulated in the contract plus the borrowed token
    uint256 public totalSupplyPrinciplePlusInterest;

    // @notice Next tokenId to be minted for ZBond Nft
    uint256 public nextTokenId;

    // @notice totaSupply to keep track of proportional share of each ZBond Nft
    uint256 public totalVirtualSupply;

    // @notice credit spread for the nft asset underlying the ZNft associated to this ZBond
    uint256 public creditSpreadMantissa;

    // @notice protocol underwriting fee
    uint256 public underwritingFeeRatioMantissa;

    // @notice Amount of underlying token that has been drawn from the PP.
    uint256 public underlyingOwedToProvisioningPool;

    // @notice days that one has to pledge in the pool to get all the awards
    uint256 public fullAwardCollectionDuration = 30 days;

    // @notice max days that one can borrow for
    uint256 public maximumLoanDuration = 180 days;

    // @notice how much time that A caller can borrow without paying interests until they get margin call
    uint256 public minimumPaymentDueFrequency = 30 days;

    // @notice days until maximum interest without penalties.
    uint256 public maximumInterestGainDuration = 270 days;

    // @notice Underlying token
    address public underlying;

    // @notice ZNft collateral
    address public ZNft;

    // @notice provisioningPool associated with the ZBond
    address public provisioningPool;

    // @notice tokenDescriptor contract that generates the nft metadata on chain
    address public tokenDescriptor;

    // @notice Contract which oversees inter-cToken operations
    address public comptroller;

    // @notice Model which tells what the current funding cost should be
    address public feeSelector;

    // @notice Zumer miner that handles the Zumer token reward calculation
    address public zumerMiner;

    // @notice A boolena flag for sanity check
    bool public isZBond;

    // @notice Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) public accountBorrows;

    // @notice Mapping of ZBond Nft tokenId to supply balances
    mapping(uint256 => SupplySnapshot) public tokenIdToSupplySnapshot;
}

abstract contract IZBond is ZBondStorage {
    function getExchangeRateMantissa() public view virtual returns (uint256);

    function getAccountCurrentBorrowBalance(address borrower) public view virtual returns (uint256);

    function getAccountBorrowBalanceAtMaturity(address borrower) public view virtual returns (uint256);

    function pledgeThenBorrow(
        uint256[] calldata tokenIds,
        uint256 amount,
        uint256 duration
    ) external virtual;

    function repayAllThenRedeem(uint256[] calldata tokenIds) external virtual;

    function mint(uint256 amount) external virtual returns (uint256);

    function redeem(uint256[] calldata tokenIds) external virtual returns (uint256);

    function redeem(uint256[] calldata tokenIds, uint256 totalVirtualBalance) external virtual returns (uint256);

    function borrow(uint256 amount, uint256 duration) external virtual;

    function borrowOnBehalf(
        uint256 amount,
        uint256 duration,
        address borrower
    ) external virtual;

    function repayBorrow(uint256 amount) external virtual;

    function repayBorrowBehalf(address borrower, uint256 amount) external virtual;

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256 tokenId
    ) external virtual returns (uint256);

    function setProvisioningPool(address newProvisioningPoolAddress, uint256 newProvisioingPoolMantissa) external virtual;

    function setUnderwritingFeeRatio(uint256 underwritingFeeRatioMantissa_) external virtual;

    function setCreditSpread(uint256 newCreditSpread) external virtual;

    function setZumerMiner(address newZumerMiner) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./IZBond.sol";

contract ZNftStorage {
    // @notice Event emitted when ZNfts are minted
    event Mint(address minter, uint256[] mintIds);
    // @notice Event emitted when tokens are redeemed
    event Redeem(address redeemer, uint256[] redeemIds);
    // @notice underlying NFT to be deposited as collateral
    address public underlying;
    // @notice comptroller contract
    address public comptroller;
    // @notice ZBond contract
    address public ZBond;

    bool public isZNft;
    // @notice tokenUri
    // TODO: if we are using the NFT's tokenURI directly we don't need this
    string public uri;
}

abstract contract IZNft is ERC721Upgradeable, IERC721Receiver, ZNftStorage {
    function mint(uint256[] calldata tokenIds, address minter) external virtual;

    function redeem(uint256[] calldata tokenIds, address redeemer) external virtual;

    function seize(
        address liquidator,
        address borrower,
        uint256 tokenId
    ) external virtual;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external virtual;

    function setZBond(address newZBond) external virtual;

    function provisioningPool() public view virtual returns (address);
}