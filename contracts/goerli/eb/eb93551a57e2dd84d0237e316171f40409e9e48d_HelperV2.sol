// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./RegistryV2.sol";

import "./interfaces/IHelper.sol";

import "./external/IYieldFarmingV1Pool.sol";
import "./external/IYieldFarmingV1Staking.sol";
import "./external/IVestingV1Epochs.sol";
import "./external/IVestingV1Cliffs.sol";
import "./external/IAirdropV1Simple.sol";
import "./external/IAirdropV1Gamified.sol";
import "./external/IDAOV1Staking.sol";
import "./external/IDAOV1Governance.sol";

contract HelperV2 is IHelper, Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address roleAdmin, address upgrader) public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function getOrganisationDetails(address orgRegistry, bytes32 orgId) public view returns (OrganisationDetails memory) {
        RegistryV2 registry = RegistryV2(orgRegistry);
        (
        bool exists,
        string memory name,
        address owner
        ) = registry.organisations(orgId);

        require(exists, "HelperV2: organisation does not exist");

        OrganisationDetails memory details;
        details.name = name;
        details.owner = owner;
        details.modules = registry.listOrganisationModules(orgId);
        details.rewardsEscrowV1 = _getValueOrZero(orgRegistry, orgId, Modules.REWARDS_ESCROW_V1, 0);

        {
            address token = _getValueOrZero(orgRegistry, orgId, Modules.TOKEN_V1, 0);
            if (token != address(0)) {
                details.tokenV1 = getTokenDetails(token);
            }
        }

        {
            address daoV1Staking = _getValueOrZero(orgRegistry, orgId, Modules.DAO_V1_STAKING, 0);
            if (daoV1Staking != address(0)) {
                details.daoV1.staking = getDAOV1_StakingDetails(daoV1Staking);
            }

            address daoV1Governance = _getValueOrZero(orgRegistry, orgId, Modules.DAO_V1_GOVERNANCE, 0);
            if (daoV1Governance != address(0)) {
                details.daoV1.governance = getDAOV1_GovernanceDetails(daoV1Governance);
            }

            address[] memory daoV1Rewards = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.DAO_V1_REWARDS);
            for (uint i = 0; i < daoV1Rewards.length; i++) {
                details.daoV1.rewards[i] = getDAOV1_RewardsDetails(daoV1Rewards[i]);
            }
        }

        {
            address yieldFarmingV1Staking = _getValueOrZero(orgRegistry, orgId, Modules.YIELDFARMING_V1_STAKING, 0);
            if (yieldFarmingV1Staking != address(0)) {
                details.yieldFarmingV1.staking = getYieldFarmingV1_StakingDetails(yieldFarmingV1Staking);

                address[] memory pools = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.YIELDFARMING_V1_POOL);
                details.yieldFarmingV1.pools = new YieldFarmingV1_PoolDetails[](pools.length);
                for (uint256 i = 0; i < pools.length; i++) {
                    details.yieldFarmingV1.pools[i] = getYieldFarmingV1_PoolDetails(pools[i]);
                }
            }
        }

        {
            address[] memory vestingV1Epochs = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.VESTING_V1_EPOCHS);
            address[] memory vestingV1Cliffs = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.VESTING_V1_CLIFFS);
            details.vestingV1 = new VestingV1Details[](vestingV1Epochs.length + vestingV1Cliffs.length);
            for (uint256 i = 0; i < vestingV1Epochs.length; i++) {
                details.vestingV1[i] = getVestingDetails(vestingV1Epochs[i]);
            }

            for (uint256 i = 0; i < vestingV1Cliffs.length; i++) {
                details.vestingV1[i + vestingV1Epochs.length] = getVestingDetails(vestingV1Cliffs[i]);
            }
        }

        {
            address[] memory airdropV1Simple = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.AIRDROP_V1_SIMPLE);
            address[] memory airdropV1Gamified = _getValuesOrEmptyArray(orgRegistry, orgId, Modules.AIRDROP_V1_GAMIFIED);
            details.airdropV1 = new AirdropV1Details[](airdropV1Simple.length + airdropV1Gamified.length);
            for (uint256 i = 0; i < airdropV1Simple.length; i++) {
                details.airdropV1[i] = getAirdropV1Details(airdropV1Simple[i]);
            }

            for (uint256 i = 0; i < airdropV1Gamified.length; i++) {
                details.airdropV1[i + airdropV1Simple.length] = getAirdropV1Details(airdropV1Gamified[i]);
            }
        }

        return details;
    }

    function getTokenDetails(address ctr) public view returns (TokenDetails memory) {
        IERC20MetadataUpgradeable t = IERC20MetadataUpgradeable(ctr);

        return TokenDetails(ctr, t.name(), t.symbol(), t.decimals());
    }

    function getDAOV1_StakingDetails(address ctr) public view returns (DAOV1_StakingDetails memory) {
        DAOV1_StakingDetails memory details;

        details.addr = ctr;
        details.state = getDAOV1_StakingState(ctr);

        return details;
    }

    function getDAOV1_StakingState(address ctr) public view returns (DAOV1_StakingState memory) {
        DAOV1_StakingState memory details;

        details.govTokenStaked = IDAOV1Staking(ctr).govTokenStaked();

        return details;
    }

    function getDAOV1_GovernanceDetails(address ctr) public view returns (DAOV1_GovernanceDetails memory) {
        DAOV1_GovernanceDetails memory details;

        details.addr = ctr;

        IDAOV1Governance c = IDAOV1Governance(ctr);
        details.isActive = c.isActive();
        details.activationThreshold = c.activationThreshold();
        details.creationThresholdPercentage = c.creationThresholdPercentage();
        details.proposalMaxActions = c.proposalMaxActions();

        details.state = getDAOV1_GovernanceState(ctr);

        return details;
    }

    function getDAOV1_GovernanceState(address ctr) public view returns (DAOV1_GovernanceState memory) {
        DAOV1_GovernanceState memory details;

        IDAOV1Governance c = IDAOV1Governance(ctr);
        details.creationThresholdAmount = c.getCreationThresholdAmount();
        details.lastProposalId = c.lastProposalId();

        return details;
    }

    function getDAOV1_RewardsDetails(address ctr) public view returns (DAOV1_RewardsDetails memory) {
        DAOV1_RewardsDetails memory details;

        details.addr = ctr;
        details.rewardToken = getTokenDetails(address(IDAOV1Rewards(ctr).rewardToken()));

        return details;
    }

    function getYieldFarmingV1_StakingDetails(address ctr) public view returns (YieldFarmingV1_StakingDetails memory) {
        YieldFarmingV1_StakingDetails memory details;

        details.addr = ctr;

        IYieldFarmingV1Staking c = IYieldFarmingV1Staking(ctr);
        details.epoch1Start = c.epoch1Start();
        details.epochDuration = c.epochDuration();
        details.state = getYieldFarmingV1_StakingState(ctr);

        return details;
    }

    function getYieldFarmingV1_StakingState(address ctr) public view returns (YieldFarmingV1_StakingState memory) {
        YieldFarmingV1_StakingState memory details;

        details.currentEpoch = IYieldFarmingV1Staking(ctr).getCurrentEpoch();

        return details;
    }

    function getYieldFarmingV1_PoolDetails(address ctr) public view returns (YieldFarmingV1_PoolDetails memory) {
        YieldFarmingV1_PoolDetails memory poolDetails;
        poolDetails.addr = ctr;

        IYieldFarmingV1Pool pool = IYieldFarmingV1Pool(ctr);
        poolDetails.totalDistributedAmount = pool.totalDistributedAmount();
        poolDetails.numberOfEpochs = pool.numberOfEpochs();
        poolDetails.epoch1Start = pool.epoch1Start();
        poolDetails.epochDuration = pool.epochDuration();
        poolDetails.rewardToken = getTokenDetails(address(pool.rewardToken()));
        poolDetails.state = getYieldFarmingV1_PoolState(ctr);

        address[] memory poolTokens = pool.getPoolTokens();

        poolDetails.poolTokens = new TokenDetails[](poolTokens.length);
        for (uint256 j = 0; j < poolTokens.length; j++) {
            poolDetails.poolTokens[j] = getTokenDetails(poolTokens[j]);
        }

        return poolDetails;
    }

    function getYieldFarmingV1_PoolState(address ctr) public view returns (YieldFarmingV1_PoolState memory) {
        YieldFarmingV1_PoolState memory state;

        IYieldFarmingV1Pool pool = IYieldFarmingV1Pool(ctr);
        state.currentEpoch = pool.getCurrentEpoch();
        state.effectivePoolSize = pool.getEpochPoolSize(state.currentEpoch);
        state.poolSize = pool.getEpochPoolSize(state.currentEpoch + 1);

        address[] memory poolTokens = pool.getPoolTokens();

        state.poolTokens = new YieldFarmingV1_PoolState_PoolToken[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; i++) {
            YieldFarmingV1_PoolState_PoolToken memory stateByToken;

            stateByToken.addr = poolTokens[i];
            stateByToken.effectivePoolSize = pool.getEpochPoolSizeByToken(poolTokens[i], state.currentEpoch);
            stateByToken.poolSize = pool.getEpochPoolSizeByToken(poolTokens[i], state.currentEpoch + 1);

            state.poolTokens[i] = stateByToken;
        }

        return state;
    }

    function getVestingDetails(address ctr) public view returns (VestingV1Details memory) {
        VestingV1Details memory details;
        details.addr = ctr;

        IVestingV1Epochs c = IVestingV1Epochs(ctr);
        details.vestingType = c.VESTING_TYPE();
        details.claimant = c.claimant();
        details.rewardToken = getTokenDetails(address(c.rewardToken()));
        details.state = getVestingV1State(ctr);

        if (details.vestingType == 1) {
            details.epochs = getVestingV1_EpochsDetails(ctr);
        } else if (details.vestingType == 2) {
            details.cliffs = getVestingV1_CliffsDetails(ctr);
        }

        return details;
    }

    function getVestingV1State(address ctr) public view returns (VestingV1State memory) {
        VestingV1State memory state;

        IVestingV1Epochs c = IVestingV1Epochs(ctr);
        state.balance = c.balance();

        (uint256 amount,) = c.getClaimableAmount();
        state.claimableAmount = amount;

        return state;
    }

    function getVestingV1_EpochsDetails(address ctr) public view returns (VestingV1_EpochsDetails memory) {
        VestingV1_EpochsDetails memory details;

        IVestingV1Epochs c = IVestingV1Epochs(ctr);
        details.numberOfEpochs = c.numberOfEpochs();
        details.epochDuration = c.epochDuration();
        details.totalDistributedAmount = c.totalDistributedAmount();
        details.state = getVestingV1_EpochsState(ctr);

        return details;
    }

    function getVestingV1_EpochsState(address ctr) public view returns (VestingV1_EpochsState memory) {
        VestingV1_EpochsState memory state;

        IVestingV1Epochs c = IVestingV1Epochs(ctr);
        state.currentEpoch = c.getCurrentEpoch();
        state.lastClaimedEpoch = c.lastClaimedEpoch();

        return state;
    }

    function getVestingV1_CliffsDetails(address ctr) public view returns (VestingV1_CliffsDetails memory) {
        VestingV1_CliffsDetails memory details;

        IVestingV1Cliffs c = IVestingV1Cliffs(ctr);
        details.totalTime = c.totalTime();
        details.startTime = c.startTime();
        details.numCliffs = c.numCliffs();

        details.cliffs = new IVestingV1Cliffs.Cliff[](details.numCliffs);

        for (uint256 i = 0; i < details.numCliffs; i++) {
            (uint256 claimablePercentage, uint256 requiredTime) = c.cliffs(i);
            details.cliffs[i] = IVestingV1Cliffs.Cliff(claimablePercentage, requiredTime);
        }

        details.state = getVestingV1_CliffsState(ctr);

        return details;
    }

    function getVestingV1_CliffsState(address ctr) public view returns (VestingV1_CliffsState memory) {
        VestingV1_CliffsState memory state;

        IVestingV1Cliffs c = IVestingV1Cliffs(ctr);
        state.timePassed = c.timePassed();
        state.lastClaimedCliff = c.lastClaimedCliff();

        return state;
    }

    function getAirdropV1Details(address ctr) public view returns (AirdropV1Details memory) {
        AirdropV1Details memory details;
        details.addr = ctr;

        IAirdropV1Simple c = IAirdropV1Simple(ctr);
        details.airdropType = c.AIRDROP_TYPE();
        details.token = getTokenDetails(c.token());
        details.totalAirdroppedAmount = c.totalAirdroppedAmount();
        details.state = getAirdropV1State(ctr);

        if (details.airdropType == 2) {
            details.gamified = getAirdropV1_GamifiedDetails(ctr);
        }

        return details;
    }

    function getAirdropV1State(address ctr) public view returns (AirdropV1State memory) {
        AirdropV1State memory state;

        state.totalClaimed = IAirdropV1Simple(ctr).totalClaimed();

        return state;
    }

    function getAirdropV1_GamifiedDetails(address ctr) public view returns (AirdropV1_GamifiedDetails memory) {
        AirdropV1_GamifiedDetails memory details;

        IAirdropV1Gamified c = IAirdropV1Gamified(ctr);
        details.numberOfAccounts = c.numberOfAccounts();
        details.gameStart = c.gameStart();
        details.gameDuration = c.gameDuration();
        details.state = getAirdropV1_GamifiedState(ctr);

        return details;
    }

    function getAirdropV1_GamifiedState(address ctr) public view returns (AirdropV1_GamifiedState memory) {
        AirdropV1_GamifiedState memory state;

        IAirdropV1Gamified c = IAirdropV1Gamified(ctr);
        state.defaultAmountUnclaimed = c.defaultAmountUnclaimed();
        state.redistributionPoolValue = c.redistributionPoolValue();

        if (c.gameStart() <= block.timestamp) {
            state.gameStarted = true;
            state.timeLeft = c.timeLeft();
        }

        return state;
    }

    function getDAOV1Governance_ProposalsList(address governance, uint256 startId, uint256 endId) public view returns (DAOV1Governance_ProposalBase[] memory) {
        DAOV1Governance_ProposalBase[] memory proposals = new DAOV1Governance_ProposalBase[](endId - startId + 1);

        for (uint256 i = startId; i <= endId; i++) {
            proposals[i - startId] = getDAOV1Governance_ProposalBase(governance, i);
        }

        return proposals;
    }

    function getDAOV1Governance_ProposalBase(address governance, uint256 id) public view returns (DAOV1Governance_ProposalBase memory) {
        DAOV1Governance_ProposalBase memory proposal;

        IDAOV1Governance d = IDAOV1Governance(governance);
        require(d.lastProposalId() >= id, "HelperV2: proposal id is out of range");

        proposal.id = id;
        proposal.currentState = d.state(id);

        (
        ,,, string memory title,,,uint256 forVotes, uint256 againstVotes,,,
        ) = d.proposals(id);
        proposal.title = title;
        proposal.forVotes = forVotes;
        proposal.againstVotes = againstVotes;

        return proposal;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "HelperV2: caller does not have upgrader role");
    }

    function _getValueOrZero(address orgRegistry, bytes32 orgId, bytes32 module, uint256 index) public view returns (address) {
        RegistryV2 registry = RegistryV2(orgRegistry);

        if (registry.hasModule(orgId, module)) {
            return registry.getModuleValue(orgId, module, index);
        }

        return address(0);
    }

    function _getValuesOrEmptyArray(address orgRegistry, bytes32 orgId, bytes32 module) public view returns (address[] memory) {
        RegistryV2 registry = RegistryV2(orgRegistry);

        if (registry.hasModule(orgId, module)) {
            return registry.getModuleValues(orgId, module);
        }

        return new address[](0);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IModule.sol";
import "./libraries/Modules.sol";
import "./libraries/Strings.sol";

contract RegistryV2 is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IFactory public factory;

    struct Organisation {
        bool exists;

        string name;
        address owner;

        bytes32[] installedModules;

        mapping(bytes32 => address[]) modules;
    }

    mapping(bytes32 => Organisation) public organisations;
    mapping(bytes32 => bytes32) public submoduleToModule;

    event OrganisationCreated(address indexed creator, bytes32 indexed orgId, string name);
    event OrganisationAddedModule(bytes32 indexed orgId, bytes32 module, bool upgradeable, address generatedAddress);
    event OrganisationRemovedModule(bytes32 indexed orgId, bytes32 module, address removedAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address factoryAddress, address roleAdmin, address upgrader) public initializer {
        __AccessControl_init();

        require(factoryAddress != address(0), "RegistryV2: invalid factory address");
        factory = IFactory(factoryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function createOrganisation(string memory _name) public {
        require(bytes(_name).length > 0, "RegistryV2: organisation name cannot be empty");
        require(Strings.isAlphanumeric(_name), "RegistryV2: organisation name must be alpha-numeric");

        bytes32 id = nameToId(_name);
        require(organisations[id].exists == false, "RegistryV2: organisation ID already exists");

        Organisation storage org = organisations[id];
        org.exists = true;
        org.name = _name;
        org.owner = msg.sender;

        emit OrganisationCreated(msg.sender, id, _name);
    }

    function deployModule(bytes32 orgId, bytes32 module, bytes memory initData, bool upgradeable) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(orgId, msg.sender);

        address addr;
        if (upgradeable) {
            addr = factory.deployModuleUUPS{value: msg.value}(module, initData);
        } else {
            addr = factory.deployModuleClone{value: msg.value}(module, initData);
        }
        IModule(addr).enforcePrerequisites(address(this), orgId);

        org.modules[module].push(addr);
        _pushModuleIfNotExists(org, module);

        emit OrganisationAddedModule(orgId, module, upgradeable, addr);
    }

    function removeModuleValue(bytes32 orgId, bytes32 module, uint256 index, address value) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(orgId, msg.sender);

        require(org.modules[module].length > 0, "RegistryV2: module does not exist");
        require(index < org.modules[module].length, "RegistryV2: index out of bounds");
        require(org.modules[module][index] == value, "RegistryV2: module address does not match");

        IModule(value).enforceSafeRemove(address(this), orgId);

        uint256 last = org.modules[module].length - 1;
        if (index != last) {
            org.modules[module][index] = org.modules[module][last];
        }
        org.modules[module].pop();

        if (org.modules[module].length == 0) {
            _removeModule(org, module);
        }

        emit OrganisationRemovedModule(orgId, module, value);
    }

    function hasModule(bytes32 orgId, bytes32 module) public view returns (bool) {
        Organisation storage org = _getOrganisationOrRevert(orgId);

        return org.modules[module].length > 0;
    }

    function getModuleValue(bytes32 orgId, bytes32 module, uint256 index) public view returns (address) {
        address[] memory values = getModuleValues(orgId, module);

        require(index < values.length, "RegistryV2: index out of bounds");

        return values[index];
    }

    function getModuleValues(bytes32 orgId, bytes32 module) public view returns (address[] memory) {
        Organisation storage org = _getOrganisationOrRevert(orgId);

        require(org.modules[module].length > 0, "RegistryV2: module does not exist");

        return org.modules[module];
    }

    function getAllModuleValues(bytes32 orgId) public view returns (bytes32[] memory, address[][] memory) {
        Organisation storage org = _getOrganisationOrRevert(orgId);

        address[][] memory values = new address[][](org.installedModules.length);
        for (uint256 i = 0; i < org.installedModules.length; i++) {
            values[i] = org.modules[org.installedModules[i]];
        }

        return (org.installedModules, values);
    }

    function listOrganisationModules(bytes32 orgId) public view returns (bytes32[] memory) {
        Organisation storage org = _getOrganisationOrRevert(orgId);

        return org.installedModules;
    }

    function nameToId(string memory name) public pure returns (bytes32) {
        return keccak256(bytes(Strings.toLower(name)));
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "RegistryV2: caller does not have upgrader role");
    }

    function _getOrganisationWithOwnerOrRevert(bytes32 id, address owner) internal view returns (Organisation storage) {
        Organisation storage org = _getOrganisationOrRevert(id);
        require(org.owner == owner, "RegistryV2: caller is not the owner");

        return org;
    }

    function _getOrganisationOrRevert(bytes32 id) internal view returns (Organisation storage) {
        Organisation storage org = organisations[id];
        require(org.exists == true, "RegistryV2: organisation does not exist");

        return org;
    }

    function _pushModuleIfNotExists(Organisation storage org, bytes32 module) internal {
        for (uint256 i = 0; i < org.installedModules.length; i++) {
            if (org.installedModules[i] == module) {
                return;
            }
        }

        org.installedModules.push(module);
    }

    function _removeModule(Organisation storage org, bytes32 module) internal {
        uint256 index = 0;
        bool found = false;
        for (uint256 i = 0; i < org.installedModules.length; i++) {
            if (org.installedModules[i] == module) {
                found = true;
                index = i;
                break;
            }
        }

        if (found) {
            if (index != org.installedModules.length - 1) {
                org.installedModules[index] = org.installedModules[org.installedModules.length - 1];
            }
            org.installedModules.pop();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../external/IVestingV1Cliffs.sol";
import "../external/IDAOV1Rewards.sol";
import "../external/IDAOV1Governance.sol";

interface IHelper {
    struct OrganisationDetails {
        string name;
        address owner;

        bytes32[] modules;

        TokenDetails tokenV1;
        address rewardsEscrowV1;
        DAOV1Details daoV1;
        YieldFarmingV1Details yieldFarmingV1;
        VestingV1Details[] vestingV1;
        AirdropV1Details[] airdropV1;
    }

    struct TokenDetails {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
    }

    struct DAOV1Details {
        DAOV1_GovernanceDetails governance;
        DAOV1_StakingDetails staking;
        DAOV1_RewardsDetails[] rewards;
    }

    struct DAOV1_GovernanceDetails {
        address addr;
        bool isActive;
        uint256 activationThreshold;
        uint256 creationThresholdPercentage;
        uint256 proposalMaxActions;

        DAOV1_GovernanceState state;
    }

    struct DAOV1_GovernanceState {
        uint256 creationThresholdAmount;
        uint256 lastProposalId;
    }

    struct DAOV1_StakingDetails {
        address addr;

        DAOV1_StakingState state;
    }

    struct DAOV1_StakingState {
        uint256 govTokenStaked;
    }

    struct DAOV1_RewardsDetails {
        address addr;

        TokenDetails rewardToken;
        IDAOV1Rewards.Pull pullConfig;
    }

    struct YieldFarmingV1Details {
        YieldFarmingV1_StakingDetails staking;
        YieldFarmingV1_PoolDetails[] pools;
    }

    struct YieldFarmingV1_StakingDetails {
        address addr;
        uint256 epoch1Start;
        uint256 epochDuration;

        YieldFarmingV1_StakingState state;
    }

    struct YieldFarmingV1_StakingState {
        uint128 currentEpoch;
    }

    struct YieldFarmingV1_PoolDetails {
        address addr;
        uint256 totalDistributedAmount;
        uint256 numberOfEpochs;
        uint256 epoch1Start;
        uint256 epochDuration;
        TokenDetails[] poolTokens;
        TokenDetails rewardToken;

        YieldFarmingV1_PoolState state;
    }

    struct YieldFarmingV1_PoolState {
        uint128 currentEpoch;
        uint256 effectivePoolSize;
        uint256 poolSize;

        YieldFarmingV1_PoolState_PoolToken[] poolTokens;
    }

    struct YieldFarmingV1_PoolState_PoolToken {
        address addr;
        uint256 effectivePoolSize;
        uint256 poolSize;
    }

    struct VestingV1Details {
        address addr;
        address claimant;
        uint8 vestingType;
        TokenDetails rewardToken;

        VestingV1State state;

        VestingV1_EpochsDetails epochs;
        VestingV1_CliffsDetails cliffs;
    }

    struct VestingV1State {
        uint256 balance;
        uint256 claimableAmount;
    }

    struct VestingV1_EpochsDetails {
        uint256 numberOfEpochs;
        uint256 epochDuration;
        uint256 totalDistributedAmount;

        VestingV1_EpochsState state;
    }

    struct VestingV1_EpochsState {
        uint256 currentEpoch;
        uint256 lastClaimedEpoch;
    }

    struct VestingV1_CliffsDetails {
        uint256 totalTime;
        uint256 totalAmount;
        uint256 startTime;
        uint256 numCliffs;
        IVestingV1Cliffs.Cliff[] cliffs;

        VestingV1_CliffsState state;
    }

    struct VestingV1_CliffsState {
        uint256 timePassed;
        uint256 lastClaimedCliff;
    }

    struct AirdropV1Details {
        address addr;
        uint8 airdropType;
        TokenDetails token;
        uint256 totalAirdroppedAmount;

        AirdropV1State state;

        AirdropV1_GamifiedDetails gamified;
    }

    struct AirdropV1State {
        uint256 totalClaimed;
    }

    struct AirdropV1_GamifiedDetails {
        uint256 numberOfAccounts;
        uint256 gameStart;
        uint256 gameDuration;

        AirdropV1_GamifiedState state;
    }

    struct AirdropV1_GamifiedState {
        uint256 defaultAmountUnclaimed;
        uint256 redistributionPoolValue;
        bool gameStarted;
        uint256 timeLeft;
    }

    struct DAOV1Governance_ProposalBase {
        uint256 id;
        string title;
        uint256 forVotes;
        uint256 againstVotes;
        IDAOV1Governance.ProposalState currentState;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IYieldFarmingV1Pool {
    struct PoolConfig {
        address[] poolTokenAddresses;
        address rewardTokenAddress;
        address stakingAddress;
        address rewardsEscrowAddress;
        uint256 totalDistributedAmount;
        uint128 numberOfEpochs;
        uint128 epochsDelayedFromStaking;
    }

    struct TokenDetails {
        address addr;
        uint8 decimals;
    }

    function rewardToken() external view returns (IERC20Upgradeable);

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function numberOfEpochs() external view returns (uint128);

    function totalDistributedAmount() external view returns (uint256);

    function initialize(PoolConfig memory cfg, address roleAdmin) external;

    function getPoolTokens() external view returns (address[] memory tokens);

    function getCurrentEpoch() external view returns (uint128);

    function getEpochPoolSize(uint128 epochId) external view returns (uint256);

    function getEpochPoolSizeByToken(address token, uint128 epochId) external view returns (uint256);

    function getEpochUserBalance(address userAddress, uint128 epochId) external view returns (uint256);

    function getEpochUserBalanceByToken(address userAddress, address token, uint128 epochId) external view returns (uint256);

    function getClaimableAmount(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IYieldFarmingV1Staking {
    struct Pool {
        uint256 size;
        bool set;
    }

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct StakingConfig {
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function initialize(StakingConfig memory cfg, address roleAdmin) external;

    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVestingV1Epochs {
    struct VestingEpochsConfig {
        address claimant;
        address rewardToken;
        uint256 startTime;
        uint256 numberOfEpochs;
        uint256 epochDuration;
        uint256 totalDistributedAmount;
    }

    function initialize(VestingEpochsConfig memory cfg, address roleAdmin) external;

    function claimant() external view returns (address);

    function numberOfEpochs() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function totalDistributedAmount() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);

    function lastClaimedEpoch() external view returns (uint256);

    function VESTING_TYPE() external view returns (uint8);

    function balance() external view returns (uint256);

    function getClaimableAmount() external view returns (uint256, uint256);

    function rewardToken() external view returns (IERC20Upgradeable);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVestingV1Cliffs {
    struct Cliff {
        uint256 ClaimablePercentage;
        uint256 RequiredTime;
    }

    struct VestingCliffsConfig {
        address claimant;
        address rewardToken;
        uint256 startTime;
        uint256 totalAmount;
        Cliff[] cliffs;
    }

    function initialize(VestingCliffsConfig memory cfg, address roleAdmin) external;

    function claimant() external view returns (address);

    function totalTime() external view returns (uint256);

    function totalAmount() external view returns (uint256);

    function startTime() external view returns (uint256);

    function cliffs(uint256 index) external view returns (uint256, uint256);

    function numCliffs() external view returns (uint256);

    function timePassed() external view returns (uint256);

    function lastClaimedCliff() external view returns (uint256);

    function VESTING_TYPE() external view returns (uint8);

    function rewardToken() external view returns (IERC20Upgradeable);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IAirdropV1Simple {
    struct AirdropConfig {
        address token;
        bytes32 merkleRoot;
        uint256 totalAirdroppedAmount;
    }

    function AIRDROP_TYPE() external view returns (uint8);

    function token() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function totalAirdroppedAmount() external view returns (uint256);

    function totalClaimed() external view returns (uint256);

    function initialize(AirdropConfig memory cfg, address roleAdmin) external;

    function claim(uint256 index, address account, uint256 amount, bytes32[] memory merkleProof) external;

    function isClaimed(uint256 index) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IAirdropV1Gamified {
    struct AirdropGamifiedConfig {
        address token;
        bytes32 merkleRoot;
        uint256 numberOfAccounts;
        uint256 totalAirdroppedAmount;
        uint256 gameStart;
        uint256 gameDuration;
    }

    function AIRDROP_TYPE() external view returns (uint8);

    function token() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function numberOfAccounts() external view returns (uint256);

    function totalAirdroppedAmount() external view returns (uint256);

    function defaultAmountUnclaimed() external view returns (uint256);

    function redistributionPoolValue() external view returns (uint256);

    function gameDuration() external view returns (uint256);

    function gameStart() external view returns (uint256);

    function totalClaimed() external view returns (uint256);

    function initialize(AirdropGamifiedConfig memory cfg, address roleAdmin) external;

    function claim(uint256 index, address account, uint256 amount, bytes32[] memory merkleProof) external;

    function calculateAmounts(uint256 defaultAmount) external view returns (uint256 claimableDefaultAmount, uint256 penaltyDefaultAmount, uint256 claimableRedistributedAmount, uint256 penaltyRedistributedAmount);

    function isClaimed(uint256 index) external view returns (bool);

    function redistributionPoolShare(uint256 defaultAmount) external view returns (uint256);

    function timeLeft() external view returns (uint256);

    function totalAmountsNow(uint256 defaultAmount) external view returns (uint256 totalClaimable, uint256 totalPenalty);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IDAOV1Staking {
    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct DAOStakingConfig {
        address govToken;
    }

    function initialize(DAOStakingConfig memory cfg, address roleAdmin) external;

    function deposit(uint256 amount) external;

    function delegate(address to) external;

    function balanceOf(address user) external view returns (uint256);

    function votingPower(address user) external view returns (uint256);

    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    function govTokenStaked() external view returns (uint256);

    function govTokenStakedAtTs(uint256 timestamp) external view returns (uint256);

    function delegatedPower(address user) external view returns (uint256);

    function userLockedUntil(address user) external view returns (uint256);

    function userDelegatedTo(address user) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../external/IDAOV1Staking.sol";

interface IDAOV1Governance {
    struct GovernanceConfig {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
        uint256 activationThreshold;
        uint256 proposalMaxActions;
        uint256 creationThresholdPercentage;
        address daoStakingAddr;
    }

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Grace,
        Expired,
        Executed,
        Abrogated
    }

    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint256 votes;
        // support
        bool support;
    }

    struct AbrogationProposal {
        address creator;
        uint256 createTime;
        string description;

        uint256 forVotes;
        uint256 againstVotes;

        mapping(address => Receipt) receipts;
    }

    struct ProposalParameters {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    }

    struct Proposal {
        // proposal identifiers
        // unique id
        uint256 id;
        // Creator of the proposal
        address proposer;
        // proposal description
        string description;
        string title;

        // proposal technical details
        // ordered list of target addresses to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // proposal creation time - 1
        uint256 createTime;

        // votes status
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        bool canceled;
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;

        ProposalParameters parameters;
    }

    function daoStaking() external view returns (IDAOV1Staking);

    function isActive() external view returns (bool);

    function activationThreshold() external view returns (uint256);

    function creationThresholdPercentage() external view returns (uint256);

    function proposalMaxActions() external view returns (uint256);

    function lastProposalId() external view returns (uint256);

    function initialize(GovernanceConfig memory cfg) external;

    function getCreationThresholdAmount() external view returns (uint256);

    function latestProposalIds(address user) external view returns (uint256);

    function proposals(uint256) external view returns (uint256 id, address proposer, string memory description, string memory title, uint256 createTime, uint256 eta, uint256 forVotes, uint256 againstVotes, bool canceled, bool executed, IDAOV1Governance.ProposalParameters memory parameters);

    function state(uint256 id) external view returns (ProposalState);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IFactory {
    function deployModuleClone(bytes32 module, bytes memory initData) external payable returns (address);

    function deployModuleUUPS(bytes32 module, bytes memory initData) external payable returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IModule {
    function enforcePrerequisites(address registryAddr, bytes32 orgId) external view;

    function enforceSafeRemove(address registryAddr, bytes32 orgId) external view;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

library Modules {
    bytes32 constant public TOKEN_V1 = keccak256("token_v1");
    bytes32 constant public DAO_V1_GOVERNANCE = keccak256("dao_v1_governance");
    bytes32 constant public DAO_V1_STAKING = keccak256("dao_v1_staking");
    bytes32 constant public DAO_V1_REWARDS = keccak256("dao_v1_rewards");
    bytes32 constant public REWARDS_ESCROW_V1 = keccak256("rewards_escrow_v1");
    bytes32 constant public YIELDFARMING_V1_STAKING = keccak256("yieldfarming_v1_staking");
    bytes32 constant public YIELDFARMING_V1_POOL = keccak256("yieldfarming_v1_pool");
    bytes32 constant public VESTING_V1_EPOCHS = keccak256("vesting_v1_epochs");
    bytes32 constant public VESTING_V1_CLIFFS = keccak256("vesting_v1_cliffs");
    bytes32 constant public AIRDROP_V1_SIMPLE = keccak256("airdrop_v1_simple");
    bytes32 constant public AIRDROP_V1_GAMIFIED = keccak256("airdrop_v1_gamified");
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

library Strings {
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }

        return string(bLower);
    }

    function isAlphanumeric(string memory str) internal pure returns (bool){
        bytes memory b = bytes(str);

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) //a-z
            )
                return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDAOV1Rewards {
    struct Pull {
        address source;
        uint256 startTs;
        uint256 endTs;
        uint256 totalDuration;
        uint256 totalAmount;
    }

    struct RewardsConfig {
        address token;
        address daoStaking;
    }

    function rewardToken() external view returns (IERC20Upgradeable);

    function initialize(RewardsConfig memory config, address roleAdmin) external;

    function registerUserAction(address user) external;

    function setupPullToken(address source, uint256 startTs, uint256 endTs, uint256 amount) external;
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