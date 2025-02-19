//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tournament.sol";

contract TournamentFactory {
    Tournament[] public tournaments;
    address[] public implementations = new address[](10);
    mapping(address => address[]) public userTournaments;

    constructor(address[] memory _implementations) {
        require(_implementations.length == 10);
        for (uint256 i = 0; i < _implementations.length; i++) {
            implementations[i] = _implementations[i];
        }
    }

    function createTournament(
        string memory title,
        address[] memory participants,
        uint256 entranceFee,
        address currencyToken,
        uint256 epochDuration,
        uint256 tournamentDuration
    ) public {
        Tournament tournament = new Tournament();
        tournament.initialize(
            title,
            participants,
            entranceFee,
            currencyToken,
            epochDuration,
            tournamentDuration,
            implementations
        );
        tournaments.push(tournament);
        for (uint256 i = 0; i < participants.length; i++) {
            userTournaments[participants[i]].push(address(tournament));
        }
    }

    function getTournaments() public view returns (Tournament[] memory) {
        return tournaments;
    }

    function getUserTournaments() public view returns (address[] memory) {
        address[] memory t = userTournaments[msg.sender];
        return t;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Interfaces/ILarvaANT.sol";
import "../Interfaces/IWorkerANT.sol";
import "../Interfaces/ISoldierANT.sol";
import "../Interfaces/IPrincessANT.sol";
import "../Interfaces/ILollipop.sol";
import "../Interfaces/IAnt.sol";
import "../Interfaces/IQueenANT.sol";
import "../Interfaces/IFunghiToken.sol";
import "../Interfaces/IFeromonToken.sol";
import "../Interfaces/IMaleANT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Tournament is Initializable {
    uint256 immutable MAX_APPROVAL = 2**256 - 1;

    struct Contracts {
        address contractAnt;
        address contractQueen;
        address contractLarva;
        address contractWorker;
        address contractSoldier;
        address contractMale;
        address contractPrincess;
        address contractLollipop;
        address contractFunghi;
        address contractFeromon;
    }
    Contracts public contracts;

    uint256 public tournamentDuration;
    string public tournamentTitle;
    uint256 public startDate;
    address public currencyToken;
    uint256 public entranceFee;
    address[] public implementations = new address[](10);
    address[] public participants;

    mapping(address => string) public nicknames;

    function initialize(
        string memory _tournamentTitle,
        address[] memory _participants,
        uint256 _entranceFee,
        address _currencyToken,
        uint256 _epochDuration, //86400 - 1 epoch = 1 gun , 1800 - 1 epoch 3 saat
        uint256 _tournamentDuration,
        address[] memory _implementations
    ) public initializer {
        tournamentTitle = _tournamentTitle;
        tournamentDuration = _tournamentDuration;
        currencyToken = _currencyToken;
        entranceFee = _entranceFee;
        contracts.contractQueen = Clones.clone(_implementations[1]);
        IQueenANT(contracts.contractQueen).initialize(_epochDuration);

        contracts.contractLarva = Clones.clone(_implementations[2]);
        ILarvaANT(contracts.contractLarva).initialize(_epochDuration);

        contracts.contractMale = Clones.clone(_implementations[5]);
        contracts.contractPrincess = Clones.clone(_implementations[6]);
        IPrincessANT(contracts.contractPrincess).initialize(_epochDuration);
        contracts.contractLollipop = Clones.clone(_implementations[7]);
        ILollipop(contracts.contractLollipop).initialize(_tournamentDuration);
        contracts.contractFunghi = Clones.clone(_implementations[8]);
        IFunghiToken(contracts.contractFunghi).initialize();
        contracts.contractFeromon = Clones.clone(_implementations[9]);
        IFeromonToken(contracts.contractFeromon).initialize();
        contracts.contractAnt = Clones.clone(_implementations[0]);
        contracts.contractWorker = Clones.clone(_implementations[3]);
        contracts.contractSoldier = Clones.clone(_implementations[4]);
        ISoldierANT(contracts.contractSoldier).initialize(
            _epochDuration,
            contracts.contractLollipop,
            contracts.contractFeromon,
            contracts.contractFunghi
        );

        IWorkerANT(contracts.contractWorker).initialize(
            _epochDuration,
            contracts.contractLollipop,
            contracts.contractFeromon,
            contracts.contractFunghi,
            contracts.contractAnt
        );
        IAnt(contracts.contractAnt).initialize(
            contracts.contractQueen,
            contracts.contractLarva,
            contracts.contractWorker,
            contracts.contractSoldier,
            contracts.contractMale,
            contracts.contractPrincess,
            contracts.contractLollipop,
            contracts.contractFunghi,
            contracts.contractFeromon
        );
        IAnt(contracts.contractAnt).addParticipants(_participants);
        for (uint256 i = 0; i < _participants.length; i++) {
            participants.push(_participants[i]);
        }
    }

    function enterTournament(string memory nickname) public payable {
        require(msg.value == entranceFee, "Pay to enter.");
        bool access = false;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == msg.sender) {
                access = true;
            }
        }
        require(access == true, "No access.");
        nicknames[msg.sender] = nickname;
        setApprovals();
        sendPack(msg.sender);
    }

    function setApprovals() private {
        IQueenANT(contracts.contractQueen).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        ILarvaANT(contracts.contractLarva).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        IWorkerANT(contracts.contractWorker).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        ISoldierANT(contracts.contractSoldier).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        IMaleANT(contracts.contractMale).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        IPrincessANT(contracts.contractPrincess).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        ILollipop(contracts.contractLollipop).setApprovalForAll(
            address(contracts.contractAnt),
            true
        );
        IFunghiToken(contracts.contractFunghi).approve(
            address(contracts.contractAnt),
            MAX_APPROVAL
        );
        IFeromonToken(contracts.contractFeromon).approve(
            address(contracts.contractAnt),
            MAX_APPROVAL
        );
    }

    function sendPack(address _user) internal {
        ILarvaANT(contracts.contractLarva).mint(_user, 10);
        ILollipop(contracts.contractLollipop).mint(_user);
    }

    function distributeRewards() public {
        require(
            startDate + tournamentDuration < block.timestamp,
            "Race isn't over yet."
        );
        address _funghiWinner = funghiWinner();
        address _feromonWinner = feromonWinner();
        address _populationWinner = populationWinner();
        uint256 rewardAmount = 266 * 1e18;
        IERC20(currencyToken).transferFrom(
            address(this),
            _funghiWinner,
            rewardAmount
        );
        IERC20(currencyToken).transferFrom(
            address(this),
            _feromonWinner,
            rewardAmount
        );
        IERC20(currencyToken).transferFrom(
            address(this),
            _populationWinner,
            rewardAmount
        );
    }

    function funghiWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance = IERC20(contracts.contractFunghi).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function feromonWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance = IERC20(contracts.contractFeromon).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function populationWinner() internal view returns (address) {
        address _winner;
        uint256 _winnerBalance;
        for (uint256 i; i < 8; i++) {
            uint256 _balance;
            _balance += IERC721(contracts.contractWorker).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractSoldier).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractQueen).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractLarva).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractMale).balanceOf(
                participants[i]
            );
            _balance += IERC721(contracts.contractPrincess).balanceOf(
                participants[i]
            );
            _winner = _balance > _winnerBalance ? participants[i] : _winner;
        }
        return _winner;
    }

    function getNickname(address _user)
        public
        view
        returns (string memory nickname)
    {
        nickname = nicknames[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILarvaANT is IERC721 {
    //variables
    function genesisCounter() external view returns (uint256);

    function PORTION_FEE() external view returns (uint256);

    function FOOD() external view returns (uint256);

    function MAX_GENESIS_MINT() external view returns (uint256);

    function LARVA_PRICE() external view returns (uint256);

    function HATCH_DURATION() external view returns (uint256);

    function MAX_GENESIS_PER_TX() external view returns (uint256);

    //functions
    function feedingLarva(
        address _user,
        uint256 _larvaAmount,
        uint256 _index
    ) external;

    function getLarvae(address _user) external view returns (uint256[] memory);

    // function getLarvaCount() external view returns(uint256);
    function genesisMint(uint256 amount) external payable;

    function getFeedable(address _user)
        external
        view
        returns (uint256 feedable);


    function getHungryLarvae (address _user) external view returns(uint256[] memory _hungryLarvae);

    function setResourceCount(uint256 _index, uint256 _amount) external;

    function getHatchersLength(address _user) external view returns (uint256);

    function getStolen(address _target, address _user, uint256 _larvaId) external;

    function mint(address _user, uint256 _amount) external;

    function burn(address _user, uint256 _index) external;

    function drain() external;

    function initialize(uint256 epochDuration) external;

    //mappings
    function idToSpawnTime(uint256) external view returns (uint256);

    function idToResource(uint256) external view returns (uint256);

    function idToFed(uint256) external view returns (bool);

    function playerToLarvae(address) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWorkerANT is IERC721 {
    //variables
    function BUILD_EPOCHS() external view returns (uint256);
    function STAKE_EPOCHS() external view returns (uint256);   
    function duration() external view returns (uint56);

    //functions
    function addMission(
        address _user,
        uint256[] memory _ids,
        uint256 _missionType,
        bool _finalized,
        uint256 speed
    ) external;

    function getWorkers(address _user) external view returns (uint256[] memory);

    function getAvailableWorkers(address _user)
        external
        view
        returns (uint256[] memory);

    function getUnHousedWorkers(address _user)
        external
        view
        returns (uint256[] memory);

    function getHomelessCount(address _user) external view returns (uint256);

    function finalizeMission(address _user, uint256 _index) external;

    function setStaked(uint256 _index, bool _status) external;

    function setHousing(uint256 _index, bool _status) external;

    function setProtected(uint256 _index, bool _status) external;

    function setBuildMission(uint256 _index, bool _status) external;

    function setHP(uint256 _index, uint256 _healthPoints) external;

    function setStakeDate(uint256 _index, uint256 _stakeDate) external;

    function setBuildDate(uint256 _index, uint256 _buildDate) external;

    function getMissionIds(address _user, uint _missionIndex) external view returns (uint256[] memory ids);

    function getMissionEnd(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _end);

    function getClaimableFunghi(address _user)
        external
        view
        returns (uint256 _funghiAmount);

    function getClaimableBB(address _user)
        external
        view
        returns (uint256 _claimableBB);

    function reduceHP(address _user, uint256 _index) external;

    function burn(address _user, uint256 _index) external;

    function mint(address _user) external;

    function getAvailableSpace(address _user)
        external
        view
        returns (uint256 capacity);

    function increaseCapacity(address _user) external;

    function decreaseAvailableSpace(address _user) external;

    function inreaseAvailableSpace(address _user) external;

    function initialize(
        uint256 epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi,
        address _ant
    ) external;

    //mappings
    function idToHealthPoints(uint256) external view returns (uint256);

    function idToStakeDate(uint256) external view returns (uint256);

    function idToBuildDate(uint256) external view returns (uint256);

    function idToStaked(uint256) external view returns (bool);

    function idToProtected(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);

    function idToOnBuildMission(uint256) external view returns (bool);

    function playerToWorkers(address) external view returns (uint256[] memory);

        struct Mission {
        uint256 start;
        uint256 end;
        uint256[] ids;
        uint256 missionType; // 0-stake, 1-build
        bool finalized;
    }
    function userMissions(address) external view returns(Mission[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISoldierANT is IERC721 {
    //variables
    function RAID_EPOCHS() external view returns (uint256);

    function HEAL_EPOCHS() external view returns (uint256);

    function HEALING_FEE() external view returns (uint256);

    function MAX_DAMAGE_COUNT() external view returns (uint256);

    function duration() external view returns (uint256);

    //functions
    function addMission(
        address _user,
        uint256[] memory _ids,
        bool _finalized,
        uint256 speed
    ) external;

    function finalizeMission(address _user, uint256 _index) external;

    function getMissionEnd(address _user, uint256 _index)
        external
        view
        returns (uint256 _end);

    function getMissionParticipantList(address _user, uint256 _index)
        external
        view
        returns (uint256[] memory missionParticipants);

    function getMissionPartipants(address _user, uint256 _index)
        external
        view
        returns (uint256 missionParticipants);

    function battle(
        uint256 attackerSoldierCount,
        uint256 targetSoldierCount,
        uint256 targetLarvaeCount
    ) external returns (uint256 prize, uint256 bonus);

    function getAvailableSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getZombieSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getInfectedSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function getSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function setStaked(uint256 _index, bool _status) external;

    function infectionSpread(address _user) external;

    function setRaidMission(uint256 _index, bool _status) external;

    function setStakeDate(uint256 _index, uint256 _stakeDate) external;

    function setRaidDate(uint256 _index, uint256 _buildDate) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedSoldiers(address _user)
        external
        view
        returns (uint256[] memory);

    function increaseDamage(uint256 _index) external;

    function reduceDamage(uint256 _index, uint256 _damageReduced) external;

    function burn(address _user, uint256 _index) external;

    function mint(address _user) external;

    function initialize(
        uint256 epochDuration,
        address _lollipop,
        address _feromon,
        address _funghi
    ) external;

    //mappings
    function idToDamageCount(uint256) external view returns (uint256);

    function idToStakeDate(uint256) external view returns (uint256);

    function idToFinalDamageDate(uint256) external view returns (uint256);

    function idToRaidDate(uint256) external view returns (uint256);

    function idToStaked(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);

    function idToOnRaidMission(uint256) external view returns (bool);

    function idToPassive(uint256) external view returns (bool);

    function playerToSoldiers(address) external view returns (uint256[] memory);

    function userMissions(address) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPrincessANT is IERC721 {
    //variables
    function MATE_EPOCHS() external view returns (uint256);

    function duration() external view returns (uint256);

    //functions
    function addMission(
        address _user,
        uint256[] memory _maleList,
        uint256[] memory _princessList,
        bool _finalized,
        uint256 _speed
    ) external;

    function finalizeMission(address _user, uint256 _index) external;

    function getMissionEnd(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _end);

    function getMissionIds(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256[] memory princessList);

    function setMatingTime(uint256) external;

    function setMatingStatus(uint256 _index) external;

    function getPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function getMatedPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedPrincesses(address _user)
        external
        view
        returns (uint256[] memory);

    function getClaimable(address _user, uint256 _missionIndex)
        external
        view
        returns (uint256 _claimable);

    function mint(address _user) external;

    function burn(address _user, uint256) external;

    function initialize(uint256 epochDuration) external;

    //mappings
    function idToMateTime(uint256) external view returns (uint256);

    function playerToPrincesses(address)
        external
        view
        returns (uint256[] memory);

    function idToVirginity(uint256) external view returns (bool);

    function idToHousing(uint256) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILollipop is IERC721 {
    function initialize(uint256 epochDuration) external;

    //mappings
    function idToTimestamp(uint256) external view returns (uint256);

    function mint(address _user) external;

    function activate(address _user) external;

    function burn(address _user) external;

    function playerToLollipopId(address _user) external view returns (uint256);

    function duration() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnt {
    function initialize(
        address queenAddress,
        address larvaAddress,
        address workerAddress,
        address soldierAddress,
        address maleAddress,
        address princessAddress,
        address lollipopAddress,
        address funghiAddress,
        address feromonAddress
    ) external;

    function addParticipants(address[] memory _participants) external;

    function increaseAvailableSpace(address _user) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IQueenANT is IERC721 {
    //variables
    function FERTILITY_DURATION() external view returns (uint256);

    function PORTION_FEE() external view returns (uint256);

    //functions
    function getQueens(address _user) external view returns (uint256[] memory);

    function setEggCount(uint256 _index, uint256 _eggCount) external;

    function setFertility(uint256 _index, bool _value) external;

    function setFertilityPoints(uint256 _index, uint256 _fertility) external;

    function resetEggCount(uint256 _index) external;

    function eggsFormula(uint256 _index)
        external
        view
        returns (uint256 _totalEggs);

    function getEpoch(uint256 _index) external view returns (uint256);

    function setTimestamp(uint256 _index, uint256 _timestamp) external;

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user) external view returns (uint256);

    function getUnHousedQueens(address _user)
        external
        view
        returns (uint256[] memory);

    function queenLevelup(uint256 _index) external;

    function feedQueen(uint256 _index) external;

    function mint(address _user) external;

    function initialize(uint256 _epochDuration) external;

    //mappings
    function idToTimestamp(uint256) external view returns (uint256);

    function idToLevel(uint256) external view returns (uint256);

    function idToEggs(uint256) external view returns (uint256);

    function idToHousing(uint256) external view returns (bool);

    function idToFertilityPoints(uint256) external view returns (uint256);

    function playerToQueens(address) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFunghiToken is IERC20 {
    //functions
    function mint(address _user, uint256 _amount) external;

    function burst(address _user) external;

    function initialize() external;

    function burn(address _user, uint256 _amount)  external; 
    //mappings
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeromonToken is IERC20 {
    //vars
    function CONVERSION_FEE() external view returns (uint256);

    function QUEEN_UPGRADE_FEE() external view returns (uint256);

    //functions
    function mint(address _user, uint256) external;

    function initialize() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMaleANT is IERC721 {
    //variables
    function MATE_DURATION() external view returns (uint256);

    //functions
    function setMatingTime(uint256) external;

    function setMatingStatus(uint256 _index) external;

    function getMales(address _user) external view returns (uint256[] memory);

    function setHousing(uint256 _index, bool _status) external;

    function getHomelessCount(address _user)
        external
        view
        returns (uint256);

    function getUnHousedMales(address _user)
        external
        view
        returns (uint256[] memory);

    function getMatedMales(address _user)
        external
        view
        returns (uint256[] memory);

    function mint(address _user) external;

    function burn(address _user, uint256) external;

    //mappings
    function idToMateTime(uint256) external view returns (uint256);

    function playerToMales(address) external view returns (uint256[] memory);

    function idToHousing(uint256) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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