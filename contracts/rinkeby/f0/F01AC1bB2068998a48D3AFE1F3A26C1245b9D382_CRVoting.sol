/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.5.17;


// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface ICRVotingOwner {
    /**
    * @dev Ensure votes can be committed for a vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    */
    function ensureCanCommit(uint256 _voteId) external;

    /**
    * @dev Ensure a certain voter can commit votes for a vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    */
    function ensureCanCommit(uint256 _voteId, address _voter) external;

    /**
    * @dev Ensure a certain voter can reveal votes for vote instance, revert otherwise
    * @param _voteId ID of the vote instance to request the weight of a voter for
    * @param _voter Address of the voter querying the weight of
    * @return Weight of the requested guardian for the requested vote instance
    */
    function ensureCanReveal(uint256 _voteId, address _voter) external returns (uint64);
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface ICRVoting {
    /**
    * @dev Create a new vote instance
    * @dev This function can only be called by the CRVoting owner
    * @param _voteId ID of the new vote instance to be created
    * @param _possibleOutcomes Number of possible outcomes for the new vote instance to be created
    */
    function createVote(uint256 _voteId, uint8 _possibleOutcomes) external;

    /**
    * @dev Get the winning outcome of a vote instance
    * @param _voteId ID of the vote instance querying the winning outcome of
    * @return Winning outcome of the given vote instance or refused in case it's missing
    */
    function getWinningOutcome(uint256 _voteId) external view returns (uint8);

    /**
    * @dev Get the tally of an outcome for a certain vote instance
    * @param _voteId ID of the vote instance querying the tally of
    * @param _outcome Outcome querying the tally of
    * @return Tally of the outcome being queried for the given vote instance
    */
    function getOutcomeTally(uint256 _voteId, uint8 _outcome) external view returns (uint256);

    /**
    * @dev Tell whether an outcome is valid for a given vote instance or not
    * @param _voteId ID of the vote instance to check the outcome of
    * @param _outcome Outcome to check if valid or not
    * @return True if the given outcome is valid for the requested vote instance, false otherwise
    */
    function isValidOutcome(uint256 _voteId, uint8 _outcome) external view returns (bool);

    /**
    * @dev Get the outcome voted by a voter for a certain vote instance
    * @param _voteId ID of the vote instance querying the outcome of
    * @param _voter Address of the voter querying the outcome of
    * @return Outcome of the voter for the given vote instance
    */
    function getVoterOutcome(uint256 _voteId, address _voter) external view returns (uint8);

    /**
    * @dev Tell whether a voter voted in favor of a certain outcome in a vote instance or not
    * @param _voteId ID of the vote instance to query if a voter voted in favor of a certain outcome
    * @param _outcome Outcome to query if the given voter voted in favor of
    * @param _voter Address of the voter to query if voted in favor of the given outcome
    * @return True if the given voter voted in favor of the given outcome, false otherwise
    */
    function hasVotedInFavorOf(uint256 _voteId, uint8 _outcome, address _voter) external view returns (bool);

    /**
    * @dev Filter a list of voters based on whether they voted in favor of a certain outcome in a vote instance or not
    * @param _voteId ID of the vote instance to be checked
    * @param _outcome Outcome to filter the list of voters of
    * @param _voters List of addresses of the voters to be filtered
    * @return List of results to tell whether a voter voted in favor of the given outcome or not
    */
    function getVotersInFavorOf(uint256 _voteId, uint8 _outcome, address[] calldata _voters) external view returns (bool[] memory);
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/IsContract.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

contract ModuleIds {
    // DisputeManager module ID - keccak256(abi.encodePacked("DISPUTE_MANAGER"))
    bytes32 internal constant MODULE_ID_DISPUTE_MANAGER = 0x14a6c70f0f6d449c014c7bbc9e68e31e79e8474fb03b7194df83109a2d888ae6;

    // GuardiansRegistry module ID - keccak256(abi.encodePacked("GUARDIANS_REGISTRY"))
    bytes32 internal constant MODULE_ID_GUARDIANS_REGISTRY = 0x8af7b7118de65da3b974a3fd4b0c702b66442f74b9dff6eaed1037254c0b79fe;

    // Voting module ID - keccak256(abi.encodePacked("VOTING"))
    bytes32 internal constant MODULE_ID_VOTING = 0x7cbb12e82a6d63ff16fe43977f43e3e2b247ecd4e62c0e340da8800a48c67346;

    // PaymentsBook module ID - keccak256(abi.encodePacked("PAYMENTS_BOOK"))
    bytes32 internal constant MODULE_ID_PAYMENTS_BOOK = 0xfa275b1417437a2a2ea8e91e9fe73c28eaf0a28532a250541da5ac0d1892b418;

    // Treasury module ID - keccak256(abi.encodePacked("TREASURY"))
    bytes32 internal constant MODULE_ID_TREASURY = 0x06aa03964db1f7257357ef09714a5f0ca3633723df419e97015e0c7a3e83edb7;
}

contract ACL {
    string private constant ERROR_BAD_FREEZE = "ACL_BAD_FREEZE";
    string private constant ERROR_ROLE_ALREADY_FROZEN = "ACL_ROLE_ALREADY_FROZEN";
    string private constant ERROR_INVALID_BULK_INPUT = "ACL_INVALID_BULK_INPUT";

    enum BulkOp { Grant, Revoke, Freeze }

    address internal constant FREEZE_FLAG = address(1);
    address internal constant ANY_ADDR = address(-1);

    // List of all roles assigned to different addresses
    mapping (bytes32 => mapping (address => bool)) public roles;

    event Granted(bytes32 indexed id, address indexed who);
    event Revoked(bytes32 indexed id, address indexed who);
    event Frozen(bytes32 indexed id);

    /**
    * @dev Tell whether an address has a role assigned
    * @param _who Address being queried
    * @param _id ID of the role being checked
    * @return True if the requested address has assigned the given role, false otherwise
    */
    function hasRole(address _who, bytes32 _id) public view returns (bool) {
        return roles[_id][_who] || roles[_id][ANY_ADDR];
    }

    /**
    * @dev Tell whether a role is frozen
    * @param _id ID of the role being checked
    * @return True if the given role is frozen, false otherwise
    */
    function isRoleFrozen(bytes32 _id) public view returns (bool) {
        return roles[_id][FREEZE_FLAG];
    }

    /**
    * @dev Internal function to grant a role to a given address
    * @param _id ID of the role to be granted
    * @param _who Address to grant the role to
    */
    function _grant(bytes32 _id, address _who) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);
        require(_who != FREEZE_FLAG, ERROR_BAD_FREEZE);

        if (!hasRole(_who, _id)) {
            roles[_id][_who] = true;
            emit Granted(_id, _who);
        }
    }

    /**
    * @dev Internal function to revoke a role from a given address
    * @param _id ID of the role to be revoked
    * @param _who Address to revoke the role from
    */
    function _revoke(bytes32 _id, address _who) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);

        if (hasRole(_who, _id)) {
            roles[_id][_who] = false;
            emit Revoked(_id, _who);
        }
    }

    /**
    * @dev Internal function to freeze a role
    * @param _id ID of the role to be frozen
    */
    function _freeze(bytes32 _id) internal {
        require(!isRoleFrozen(_id), ERROR_ROLE_ALREADY_FROZEN);
        roles[_id][FREEZE_FLAG] = true;
        emit Frozen(_id);
    }

    /**
    * @dev Internal function to enact a bulk list of ACL operations
    */
    function _bulk(BulkOp[] memory _op, bytes32[] memory _id, address[] memory _who) internal {
        require(_op.length == _id.length && _op.length == _who.length, ERROR_INVALID_BULK_INPUT);

        for (uint256 i = 0; i < _op.length; i++) {
            BulkOp op = _op[i];
            if (op == BulkOp.Grant) {
                _grant(_id[i], _who[i]);
            } else if (op == BulkOp.Revoke) {
                _revoke(_id[i], _who[i]);
            } else if (op == BulkOp.Freeze) {
                _freeze(_id[i]);
            }
        }
    }
}

interface IModulesLinker {
    /**
    * @notice Update the implementations of a list of modules
    * @param _ids List of IDs of the modules to be updated
    * @param _addresses List of module addresses to be updated
    */
    function linkModules(bytes32[] calldata _ids, address[] calldata _addresses) external;
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath64.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules
contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

interface IClock {
    /**
    * @dev Ensure that the current term of the clock is up-to-date
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64);

    /**
    * @dev Transition up to a certain number of terms to leave the clock up-to-date
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64);

    /**
    * @dev Ensure that a certain term has its randomness set
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32);

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64);

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64);

    /**
    * @dev Tell the number of terms the clock should transition to be up-to-date
    * @return Number of terms the clock should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64);

    /**
    * @dev Tell the information related to a term based on its ID
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness);

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view returns (bytes32);
}

contract CourtClock is IClock, TimeHelpers {
    using SafeMath64 for uint64;

    string private constant ERROR_TERM_DOES_NOT_EXIST = "CLK_TERM_DOES_NOT_EXIST";
    string private constant ERROR_TERM_DURATION_TOO_LONG = "CLK_TERM_DURATION_TOO_LONG";
    string private constant ERROR_TERM_RANDOMNESS_NOT_YET = "CLK_TERM_RANDOMNESS_NOT_YET";
    string private constant ERROR_TERM_RANDOMNESS_UNAVAILABLE = "CLK_TERM_RANDOMNESS_UNAVAILABLE";
    string private constant ERROR_BAD_FIRST_TERM_START_TIME = "CLK_BAD_FIRST_TERM_START_TIME";
    string private constant ERROR_TOO_MANY_TRANSITIONS = "CLK_TOO_MANY_TRANSITIONS";
    string private constant ERROR_INVALID_TRANSITION_TERMS = "CLK_INVALID_TRANSITION_TERMS";
    string private constant ERROR_CANNOT_DELAY_STARTED_COURT = "CLK_CANNOT_DELAY_STARTED_PROT";
    string private constant ERROR_CANNOT_DELAY_PAST_START_TIME = "CLK_CANNOT_DELAY_PAST_START_TIME";

    // Maximum number of term transitions a callee may have to assume in order to call certain functions that require the Court being up-to-date
    uint64 internal constant MAX_AUTO_TERM_TRANSITIONS_ALLOWED = 1;

    // Max duration in seconds that a term can last
    uint64 internal constant MAX_TERM_DURATION = 365 days;

    // Max time until first term starts since contract is deployed
    uint64 internal constant MAX_FIRST_TERM_DELAY_PERIOD = 2 * MAX_TERM_DURATION;

    struct Term {
        uint64 startTime;              // Timestamp when the term started
        uint64 randomnessBN;           // Block number for entropy
        bytes32 randomness;            // Entropy from randomnessBN block hash
    }

    // Duration in seconds for each term of the Court
    uint64 private termDuration;

    // Last ensured term id
    uint64 private termId;

    // List of Court terms indexed by id
    mapping (uint64 => Term) private terms;

    event Heartbeat(uint64 previousTermId, uint64 currentTermId);
    event StartTimeDelayed(uint64 previousStartTime, uint64 currentStartTime);

    /**
    * @dev Ensure a certain term has already been processed
    * @param _termId Identification number of the term to be checked
    */
    modifier termExists(uint64 _termId) {
        require(_termId <= termId, ERROR_TERM_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for guardian on-boarding)
    */
    constructor(uint64[2] memory _termParams) public {
        uint64 _termDuration = _termParams[0];
        uint64 _firstTermStartTime = _termParams[1];

        require(_termDuration < MAX_TERM_DURATION, ERROR_TERM_DURATION_TOO_LONG);
        require(_firstTermStartTime >= getTimestamp64() + _termDuration, ERROR_BAD_FIRST_TERM_START_TIME);
        require(_firstTermStartTime <= getTimestamp64() + MAX_FIRST_TERM_DELAY_PERIOD, ERROR_BAD_FIRST_TERM_START_TIME);

        termDuration = _termDuration;

        // No need for SafeMath: we already checked values above
        terms[0].startTime = _firstTermStartTime - _termDuration;
    }

    /**
    * @notice Ensure that the current term of the Court is up-to-date. If the Court is outdated by more than `MAX_AUTO_TERM_TRANSITIONS_ALLOWED`
    *         terms, the heartbeat function must be called manually instead.
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64) {
        return _ensureCurrentTerm();
    }

    /**
    * @notice Transition up to `_maxRequestedTransitions` terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64) {
        return _heartbeat(_maxRequestedTransitions);
    }

    /**
    * @notice Ensure that a certain term has its randomness set. As we allow to draft disputes requested for previous terms, if there
    *      were mined more than 256 blocks for the current term, the blockhash of its randomness BN is no longer available, given
    *      round will be able to be drafted in the following term.
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32) {
        // If the randomness for the given term was already computed, return
        uint64 currentTermId = termId;
        Term storage term = terms[currentTermId];
        bytes32 termRandomness = term.randomness;
        if (termRandomness != bytes32(0)) {
            return termRandomness;
        }

        // Compute term randomness
        bytes32 newRandomness = _computeTermRandomness(currentTermId);
        require(newRandomness != bytes32(0), ERROR_TERM_RANDOMNESS_UNAVAILABLE);
        term.randomness = newRandomness;
        return newRandomness;
    }

    /**
    * @dev Tell the term duration of the Court
    * @return Duration in seconds of the Court term
    */
    function getTermDuration() external view returns (uint64) {
        return termDuration;
    }

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64) {
        return _lastEnsuredTermId();
    }

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64) {
        return _currentTermId();
    }

    /**
    * @dev Tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64) {
        return _neededTermTransitions();
    }

    /**
    * @dev Tell the information related to a term based on its ID. Note that if the term has not been reached, the
    *      information returned won't be computed yet. This function allows querying future terms that were not computed yet.
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness) {
        Term storage term = terms[_termId];
        return (term.startTime, term.randomnessBN, term.randomness);
    }

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view termExists(_termId) returns (bytes32) {
        return _computeTermRandomness(_termId);
    }

    /**
    * @dev Internal function to ensure that the current term of the Court is up-to-date. If the Court is outdated by more than
    *      `MAX_AUTO_TERM_TRANSITIONS_ALLOWED` terms, the heartbeat function must be called manually.
    * @return Identification number of the resultant term ID after executing the corresponding transitions
    */
    function _ensureCurrentTerm() internal returns (uint64) {
        // Check the required number of transitions does not exceeds the max allowed number to be processed automatically
        uint64 requiredTransitions = _neededTermTransitions();
        require(requiredTransitions <= MAX_AUTO_TERM_TRANSITIONS_ALLOWED, ERROR_TOO_MANY_TRANSITIONS);

        // If there are no transitions pending, return the last ensured term id
        if (uint256(requiredTransitions) == 0) {
            return termId;
        }

        // Process transition if there is at least one pending
        return _heartbeat(requiredTransitions);
    }

    /**
    * @dev Internal function to transition the Court terms up to a requested number of terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the resultant term ID after executing the requested transitions
    */
    function _heartbeat(uint64 _maxRequestedTransitions) internal returns (uint64) {
        // Transition the minimum number of terms between the amount requested and the amount actually needed
        uint64 neededTransitions = _neededTermTransitions();
        uint256 transitions = uint256(_maxRequestedTransitions < neededTransitions ? _maxRequestedTransitions : neededTransitions);
        require(transitions > 0, ERROR_INVALID_TRANSITION_TERMS);

        uint64 blockNumber = getBlockNumber64();
        uint64 previousTermId = termId;
        uint64 currentTermId = previousTermId;
        for (uint256 transition = 1; transition <= transitions; transition++) {
            // Term IDs are incremented by one based on the number of time periods since the Court started. Since time is represented in uint64,
            // even if we chose the minimum duration possible for a term (1 second), we can ensure terms will never reach 2^64 since time is
            // already assumed to fit in uint64.
            Term storage previousTerm = terms[currentTermId++];
            Term storage currentTerm = terms[currentTermId];
            _onTermTransitioned(currentTermId);

            // Set the start time of the new term. Note that we are using a constant term duration value to guarantee
            // equally long terms, regardless of heartbeats.
            currentTerm.startTime = previousTerm.startTime.add(termDuration);

            // In order to draft a random number of guardians in a term, we use a randomness factor for each term based on a
            // block number that is set once the term has started. Note that this information could not be known beforehand.
            currentTerm.randomnessBN = blockNumber + 1;
        }

        termId = currentTermId;
        emit Heartbeat(previousTermId, currentTermId);
        return currentTermId;
    }

    /**
    * @dev Internal function to delay the first term start time only if it wasn't reached yet
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function _delayStartTime(uint64 _newFirstTermStartTime) internal {
        require(_currentTermId() == 0, ERROR_CANNOT_DELAY_STARTED_COURT);

        Term storage term = terms[0];
        uint64 currentFirstTermStartTime = term.startTime.add(termDuration);
        require(_newFirstTermStartTime > currentFirstTermStartTime, ERROR_CANNOT_DELAY_PAST_START_TIME);

        // No need for SafeMath: we already checked above that `_newFirstTermStartTime` > `currentFirstTermStartTime` >= `termDuration`
        term.startTime = _newFirstTermStartTime - termDuration;
        emit StartTimeDelayed(currentFirstTermStartTime, _newFirstTermStartTime);
    }

    /**
    * @dev Internal function to notify when a term has been transitioned. This function must be overridden to provide custom behavior.
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal;

    /**
    * @dev Internal function to tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function _lastEnsuredTermId() internal view returns (uint64) {
        return termId;
    }

    /**
    * @dev Internal function to tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function _currentTermId() internal view returns (uint64) {
        return termId.add(_neededTermTransitions());
    }

    /**
    * @dev Internal function to tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function _neededTermTransitions() internal view returns (uint64) {
        // Note that the Court is always initialized providing a start time for the first-term in the future. If that's the case,
        // no term transitions are required.
        uint64 currentTermStartTime = terms[termId].startTime;
        if (getTimestamp64() < currentTermStartTime) {
            return uint64(0);
        }

        // No need for SafeMath: we already know that the start time of the current term is in the past
        return (getTimestamp64() - currentTermStartTime) / termDuration;
    }

    /**
    * @dev Internal function to compute the randomness that will be used to draft guardians for the given term. This
    *      function assumes the given term exists. To determine the randomness factor for a term we use the hash of a
    *      block number that is set once the term has started to ensure it cannot be known beforehand. Note that the
    *      hash function being used only works for the 256 most recent block numbers.
    * @param _termId Identification number of the term being queried
    * @return Randomness computed for the given term
    */
    function _computeTermRandomness(uint64 _termId) internal view returns (bytes32) {
        Term storage term = terms[_termId];
        require(getBlockNumber64() > term.randomnessBN, ERROR_TERM_RANDOMNESS_NOT_YET);
        return blockhash(term.randomnessBN);
    }
}

library PctHelpers {
    using SafeMath for uint256;

    uint256 internal constant PCT_BASE = 10000; // ‱ (1 / 10,000)

    function isValid(uint16 _pct) internal pure returns (bool) {
        return _pct <= PCT_BASE;
    }

    function pct(uint256 self, uint16 _pct) internal pure returns (uint256) {
        return self.mul(uint256(_pct)) / PCT_BASE;
    }

    function pct256(uint256 self, uint256 _pct) internal pure returns (uint256) {
        return self.mul(_pct) / PCT_BASE;
    }

    function pctIncrease(uint256 self, uint16 _pct) internal pure returns (uint256) {
        // No need for SafeMath: for addition note that `PCT_BASE` is lower than (2^256 - 2^16)
        return self.mul(PCT_BASE + uint256(_pct)) / PCT_BASE;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IConfig {

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);
}

contract CourtConfigData {
    struct Config {
        FeesConfig fees;                        // Full fees-related config
        DisputesConfig disputes;                // Full disputes-related config
        uint256 minActiveBalance;               // Minimum amount of tokens guardians have to activate to participate in the Court
    }

    struct FeesConfig {
        IERC20 token;                           // ERC20 token to be used for the fees of the Court
        uint16 finalRoundReduction;             // Permyriad of fees reduction applied for final appeal round (‱ - 1/10,000)
        uint256 guardianFee;                    // Amount of tokens paid to draft a guardian to adjudicate a dispute
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting guardians
        uint256 settleFee;                      // Amount of tokens paid per round to cover the costs of slashing guardians
    }

    struct DisputesConfig {
        uint64 evidenceTerms;                   // Max submitting evidence period duration in terms
        uint64 commitTerms;                     // Committing period duration in terms
        uint64 revealTerms;                     // Revealing period duration in terms
        uint64 appealTerms;                     // Appealing period duration in terms
        uint64 appealConfirmTerms;              // Confirmation appeal period duration in terms
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
        uint64 firstRoundGuardiansNumber;       // Number of guardians drafted on first round
        uint64 appealStepFactor;                // Factor in which the guardians number is increased on each appeal
        uint64 finalRoundLockTerms;             // Period a coherent guardian in the final round will remain locked
        uint256 maxRegularAppealRounds;         // Before the final appeal
        uint256 appealCollateralFactor;         // Permyriad multiple of dispute fees required to appeal a preliminary ruling (‱ - 1/10,000)
        uint256 appealConfirmCollateralFactor;  // Permyriad multiple of dispute fees required to confirm appeal (‱ - 1/10,000)
    }

    struct DraftConfig {
        IERC20 feeToken;                         // ERC20 token to be used for the fees of the Court
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting guardians
    }
}

contract CourtConfig is IConfig, CourtConfigData {
    using SafeMath64 for uint64;
    using PctHelpers for uint256;

    string private constant ERROR_TOO_OLD_TERM = "CONF_TOO_OLD_TERM";
    string private constant ERROR_INVALID_PENALTY_PCT = "CONF_INVALID_PENALTY_PCT";
    string private constant ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT = "CONF_INVALID_FINAL_ROUND_RED_PCT";
    string private constant ERROR_INVALID_MAX_APPEAL_ROUNDS = "CONF_INVALID_MAX_APPEAL_ROUNDS";
    string private constant ERROR_LARGE_ROUND_PHASE_DURATION = "CONF_LARGE_ROUND_PHASE_DURATION";
    string private constant ERROR_BAD_INITIAL_GUARDIANS_NUMBER = "CONF_BAD_INITIAL_GUARDIAN_NUMBER";
    string private constant ERROR_BAD_APPEAL_STEP_FACTOR = "CONF_BAD_APPEAL_STEP_FACTOR";
    string private constant ERROR_ZERO_COLLATERAL_FACTOR = "CONF_ZERO_COLLATERAL_FACTOR";
    string private constant ERROR_ZERO_MIN_ACTIVE_BALANCE = "CONF_ZERO_MIN_ACTIVE_BALANCE";

    // Max number of terms that each of the different adjudication states can last (if lasted 1h, this would be a year)
    uint64 internal constant MAX_ADJ_STATE_DURATION = 8670;

    // Cap the max number of regular appeal rounds
    uint256 internal constant MAX_REGULAR_APPEAL_ROUNDS_LIMIT = 10;

    // Future term ID in which a config change has been scheduled
    uint64 private configChangeTermId;

    // List of all the configs used in the Court
    Config[] private configs;

    // List of configs indexed by id
    mapping (uint64 => uint256) private configIdByTerm;

    event NewConfig(uint64 fromTermId, uint64 courtConfigId);

    /**
    * @dev Constructor function
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    constructor(
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        public
    {
        // Leave config at index 0 empty for non-scheduled config changes
        configs.length = 1;
        _setConfig(
            0,
            0,
            _feeToken,
            _fees,
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
        );
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell the term identification number of the next scheduled config change
    * @return Term identification number of the next scheduled config change
    */
    function getConfigChangeTermId() external view returns (uint64) {
        return configChangeTermId;
    }

    /**
    * @dev Internal to make sure to set a config for the new term, it will copy the previous term config if none
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _ensureTermConfig(uint64 _termId) internal {
        // If the term being transitioned had no config change scheduled, keep the previous one
        uint256 currentConfigId = configIdByTerm[_termId];
        if (currentConfigId == 0) {
            uint256 previousConfigId = configIdByTerm[_termId.sub(1)];
            configIdByTerm[_termId] = previousConfigId;
        }
    }

    /**
    * @dev Assumes that sender it's allowed (either it's from governor or it's on init)
    * @param _termId Identification number of the current Court term
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees.
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function _setConfig(
        uint64 _termId,
        uint64 _fromTermId,
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        internal
    {
        // If the current term is not zero, changes must be scheduled at least after the current period.
        // No need to ensure delays for on-going disputes since these already use their creation term for that.
        require(_termId == 0 || _fromTermId > _termId, ERROR_TOO_OLD_TERM);

        // Make sure appeal collateral factors are greater than zero
        require(_appealCollateralParams[0] > 0 && _appealCollateralParams[1] > 0, ERROR_ZERO_COLLATERAL_FACTOR);

        // Make sure the given penalty and final round reduction pcts are not greater than 100%
        require(PctHelpers.isValid(_pcts[0]), ERROR_INVALID_PENALTY_PCT);
        require(PctHelpers.isValid(_pcts[1]), ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT);

        // Disputes must request at least one guardian to be drafted initially
        require(_roundParams[0] > 0, ERROR_BAD_INITIAL_GUARDIANS_NUMBER);

        // Prevent that further rounds have zero guardians
        require(_roundParams[1] > 0, ERROR_BAD_APPEAL_STEP_FACTOR);

        // Make sure the max number of appeals allowed does not reach the limit
        uint256 _maxRegularAppealRounds = _roundParams[2];
        bool isMaxAppealRoundsValid = _maxRegularAppealRounds > 0 && _maxRegularAppealRounds <= MAX_REGULAR_APPEAL_ROUNDS_LIMIT;
        require(isMaxAppealRoundsValid, ERROR_INVALID_MAX_APPEAL_ROUNDS);

        // Make sure each adjudication round phase duration is valid
        for (uint i = 0; i < _roundStateDurations.length; i++) {
            require(_roundStateDurations[i] > 0 && _roundStateDurations[i] < MAX_ADJ_STATE_DURATION, ERROR_LARGE_ROUND_PHASE_DURATION);
        }

        // Make sure min active balance is not zero
        require(_minActiveBalance > 0, ERROR_ZERO_MIN_ACTIVE_BALANCE);

        // If there was a config change already scheduled, reset it (in that case we will overwrite last array item).
        // Otherwise, schedule a new config.
        if (configChangeTermId > _termId) {
            configIdByTerm[configChangeTermId] = 0;
        } else {
            configs.length++;
        }

        uint64 courtConfigId = uint64(configs.length - 1);
        Config storage config = configs[courtConfigId];

        config.fees = FeesConfig({
            token: _feeToken,
            guardianFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            evidenceTerms: _roundStateDurations[0],
            commitTerms: _roundStateDurations[1],
            revealTerms: _roundStateDurations[2],
            appealTerms: _roundStateDurations[3],
            appealConfirmTerms: _roundStateDurations[4],
            penaltyPct: _pcts[0],
            firstRoundGuardiansNumber: _roundParams[0],
            appealStepFactor: _roundParams[1],
            maxRegularAppealRounds: _maxRegularAppealRounds,
            finalRoundLockTerms: _roundParams[3],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.minActiveBalance = _minActiveBalance;

        configIdByTerm[_fromTermId] = courtConfigId;
        configChangeTermId = _fromTermId;

        emit NewConfig(_fromTermId, courtConfigId);
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function _getConfigAt(uint64 _termId, uint64 _lastEnsuredTermId) internal view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);

        FeesConfig storage feesConfig = config.fees;
        feeToken = feesConfig.token;
        fees = [feesConfig.guardianFee, feesConfig.draftFee, feesConfig.settleFee];

        DisputesConfig storage disputesConfig = config.disputes;
        roundStateDurations = [
            disputesConfig.evidenceTerms,
            disputesConfig.commitTerms,
            disputesConfig.revealTerms,
            disputesConfig.appealTerms,
            disputesConfig.appealConfirmTerms
        ];
        pcts = [disputesConfig.penaltyPct, feesConfig.finalRoundReduction];
        roundParams = [
            disputesConfig.firstRoundGuardiansNumber,
            disputesConfig.appealStepFactor,
            uint64(disputesConfig.maxRegularAppealRounds),
            disputesConfig.finalRoundLockTerms
        ];
        appealCollateralParams = [disputesConfig.appealCollateralFactor, disputesConfig.appealConfirmCollateralFactor];

        minActiveBalance = config.minActiveBalance;
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function _getDraftConfig(uint64 _termId,  uint64 _lastEnsuredTermId) internal view
        returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct)
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return (config.fees.token, config.fees.draftFee, config.disputes.penaltyPct);
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Minimum amount of guardian tokens that can be activated at the given term
    */
    function _getMinActiveBalance(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return config.minActiveBalance;
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Court config for the given term
    */
    function _getConfigFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (Config storage) {
        uint256 id = _getConfigIdFor(_termId, _lastEnsuredTermId);
        return configs[id];
    }

    /**
    * @dev Internal function to get the Court config ID for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Identification number of the config for the given terms
    */
    function _getConfigIdFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        // If the given term is lower or equal to the last ensured Court term, it is safe to use a past Court config
        if (_termId <= _lastEnsuredTermId) {
            return configIdByTerm[_termId];
        }

        // If the given term is in the future but there is a config change scheduled before it, use the incoming config
        uint64 scheduledChangeTermId = configChangeTermId;
        if (scheduledChangeTermId <= _termId) {
            return configIdByTerm[scheduledChangeTermId];
        }

        // If no changes are scheduled, use the Court config of the last ensured term
        return configIdByTerm[_lastEnsuredTermId];
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Court
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence related to the dispute
    */
    function submitEvidence(uint256 _disputeId, address _submitter, bytes calldata _evidence) external;

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @notice Rule dispute #`_disputeId` if ready
    * @param _disputeId Identification number of the dispute to be ruled
    * @return subject Subject associated to the dispute
    * @return ruling Ruling number computed for the given dispute
    */
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, IERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the payments recipient address
    * @return Address of the payments recipient module
    */
    function getPaymentsRecipient() external view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */
/**
* @dev The Arbitrable instances actually don't require to follow any specific interface.
*      Note that this is actually optional, although it does allow the Court to at least have a way to identify a specific set of instances.
*/
contract IArbitrable {
    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);
}

interface IDisputeManager {
    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    enum AdjudicationState {
        Invalid,
        Committing,
        Revealing,
        Appealing,
        ConfirmingAppeal,
        Ended
    }

    /**
    * @dev Create a dispute to be drafted in a future term
    * @param _subject Arbitrable instance creating the dispute
    * @param _possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(IArbitrable _subject, uint8 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Submit evidence for a dispute
    * @param _subject Arbitrable instance submitting the dispute
    * @param _disputeId Identification number of the dispute receiving new evidence
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence of the dispute
    */
    function submitEvidence(IArbitrable _subject, uint256 _disputeId, address _submitter, bytes calldata _evidence) external;

    /**
    * @dev Close the evidence period of a dispute
    * @param _subject IArbitrable instance requesting to close the evidence submission period
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(IArbitrable _subject, uint256 _disputeId) external;

    /**
    * @dev Draft guardians for the next round of a dispute
    * @param _disputeId Identification number of the dispute to be drafted
    */
    function draft(uint256 _disputeId) external;

    /**
    * @dev Appeal round of a dispute in favor of a certain ruling
    * @param _disputeId Identification number of the dispute being appealed
    * @param _roundId Identification number of the dispute round being appealed
    * @param _ruling Ruling appealing a dispute round in favor of
    */
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Confirm appeal for a round of a dispute in favor of a ruling
    * @param _disputeId Identification number of the dispute confirming an appeal of
    * @param _roundId Identification number of the dispute round confirming an appeal of
    * @param _ruling Ruling being confirmed against a dispute round appeal
    */
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Compute the final ruling for a dispute
    * @param _disputeId Identification number of the dispute to compute its final ruling
    * @return subject Arbitrable instance associated to the dispute
    * @return finalRuling Final ruling decided for the given dispute
    */
    function computeRuling(uint256 _disputeId) external returns (IArbitrable subject, uint8 finalRuling);

    /**
    * @dev Settle penalties for a round of a dispute
    * @param _disputeId Identification number of the dispute to settle penalties for
    * @param _roundId Identification number of the dispute round to settle penalties for
    * @param _guardiansToSettle Maximum number of guardians to be slashed in this call
    */
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _guardiansToSettle) external;

    /**
    * @dev Claim rewards for a round of a dispute for guardian
    * @dev For regular rounds, it will only reward winning guardians
    * @param _disputeId Identification number of the dispute to settle rewards for
    * @param _roundId Identification number of the dispute round to settle rewards for
    * @param _guardian Address of the guardian to settle their rewards
    */
    function settleReward(uint256 _disputeId, uint256 _roundId, address _guardian) external;

    /**
    * @dev Settle appeal deposits for a round of a dispute
    * @param _disputeId Identification number of the dispute to settle appeal deposits for
    * @param _roundId Identification number of the dispute round to settle appeal deposits for
    */
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external;

    /**
    * @dev Tell the amount of token fees required to create a dispute
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees to be paid for a dispute at the given term
    */
    function getDisputeFees() external view returns (IERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
    * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled
    * @return finalRuling The winning ruling in case the dispute is finished
    * @return lastRoundId Identification number of the last round created for the dispute
    * @return createTermId Identification number of the term when the dispute was created
    */
    function getDispute(uint256 _disputeId) external view
        returns (IArbitrable subject, uint8 possibleRulings, DisputeState state, uint8 finalRuling, uint256 lastRoundId, uint64 createTermId);

    /**
    * @dev Tell information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return draftTerm Term from which the requested round can be drafted
    * @return delayedTerms Number of terms the given round was delayed based on its requested draft term id
    * @return guardiansNumber Number of guardians requested for the round
    * @return selectedGuardians Number of guardians already selected for the requested round
    * @return settledPenalties Whether or not penalties have been settled for the requested round
    * @return collectedTokens Amount of guardian tokens that were collected from slashed guardians for the requested round
    * @return coherentGuardians Number of guardians that voted in favor of the final ruling in the requested round
    * @return state Adjudication state of the requested round
    */
    function getRound(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 guardiansNumber,
            uint64 selectedGuardians,
            uint256 guardianFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentGuardians,
            AdjudicationState state
        );

    /**
    * @dev Tell appeal-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return maker Address of the account appealing the given round
    * @return appealedRuling Ruling confirmed by the appealer of the given round
    * @return taker Address of the account confirming the appeal of the given round
    * @return opposedRuling Ruling confirmed by the appeal taker of the given round
    */
    function getAppeal(uint256 _disputeId, uint256 _roundId) external view
        returns (address maker, uint64 appealedRuling, address taker, uint64 opposedRuling);

    /**
    * @dev Tell information related to the next round due to an appeal of a certain round given.
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round requesting the appeal details of
    * @return nextRoundStartTerm Term ID from which the next round will start
    * @return nextRoundGuardiansNumber Guardians number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return guardianFees Total amount of fees to be distributed between the winning guardians of the next round
    * @return totalFees Total amount of fees for a regular round at the given term
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundGuardiansNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 guardianFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );

    /**
    * @dev Tell guardian-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @param _guardian Address of the guardian being queried
    * @return weight Guardian weight drafted for the requested round
    * @return rewarded Whether or not the given guardian was rewarded based on the requested round
    */
    function getGuardian(uint256 _disputeId, uint256 _roundId, address _guardian) external view returns (uint64 weight, bool rewarded);
}

contract Controller is IsContract, ModuleIds, CourtClock, CourtConfig, ACL {
    string private constant ERROR_SENDER_NOT_GOVERNOR = "CTR_SENDER_NOT_GOVERNOR";
    string private constant ERROR_INVALID_GOVERNOR_ADDRESS = "CTR_INVALID_GOVERNOR_ADDRESS";
    string private constant ERROR_MODULE_NOT_SET = "CTR_MODULE_NOT_SET";
    string private constant ERROR_MODULE_ALREADY_ENABLED = "CTR_MODULE_ALREADY_ENABLED";
    string private constant ERROR_MODULE_ALREADY_DISABLED = "CTR_MODULE_ALREADY_DISABLED";
    string private constant ERROR_DISPUTE_MANAGER_NOT_ACTIVE = "CTR_DISPUTE_MANAGER_NOT_ACTIVE";
    string private constant ERROR_CUSTOM_FUNCTION_NOT_SET = "CTR_CUSTOM_FUNCTION_NOT_SET";
    string private constant ERROR_IMPLEMENTATION_NOT_CONTRACT = "CTR_IMPLEMENTATION_NOT_CONTRACT";
    string private constant ERROR_INVALID_IMPLS_INPUT_LENGTH = "CTR_INVALID_IMPLS_INPUT_LENGTH";

    address private constant ZERO_ADDRESS = address(0);

    /**
    * @dev Governor of the whole system. Set of three addresses to recover funds, change configuration settings and setup modules
    */
    struct Governor {
        address funds;      // This address can be unset at any time. It is allowed to recover funds from the ControlledRecoverable modules
        address config;     // This address is meant not to be unset. It is allowed to change the different configurations of the whole system
        address modules;    // This address can be unset at any time. It is allowed to plug/unplug modules from the system
    }

    /**
    * @dev Module information
    */
    struct Module {
        bytes32 id;         // ID associated to a module
        bool disabled;      // Whether the module is disabled
    }

    // Governor addresses of the system
    Governor private governor;

    // List of current modules registered for the system indexed by ID
    mapping (bytes32 => address) internal currentModules;

    // List of all historical modules registered for the system indexed by address
    mapping (address => Module) internal allModules;

    // List of custom function targets indexed by signature
    mapping (bytes4 => address) internal customFunctions;

    event ModuleSet(bytes32 id, address addr);
    event ModuleEnabled(bytes32 id, address addr);
    event ModuleDisabled(bytes32 id, address addr);
    event CustomFunctionSet(bytes4 signature, address target);
    event FundsGovernorChanged(address previousGovernor, address currentGovernor);
    event ConfigGovernorChanged(address previousGovernor, address currentGovernor);
    event ModulesGovernorChanged(address previousGovernor, address currentGovernor);

    /**
    * @dev Ensure the msg.sender is the funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == governor.funds, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == governor.config, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyModulesGovernor {
        require(msg.sender == governor.modules, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the given dispute manager is active
    */
    modifier onlyActiveDisputeManager(IDisputeManager _disputeManager) {
        require(!_isModuleDisabled(address(_disputeManager)), ERROR_DISPUTE_MANAGER_NOT_ACTIVE);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for guardian on-boarding)
    * @param _governors Array containing:
    *        0. _fundsGovernor Address of the funds governor
    *        1. _configGovernor Address of the config governor
    *        2. _modulesGovernor Address of the modules governor
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted guardians (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    constructor(
        uint64[2] memory _termParams,
        address[3] memory _governors,
        IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        public
        CourtClock(_termParams)
        CourtConfig(_feeToken, _fees, _roundStateDurations, _pcts, _roundParams, _appealCollateralParams, _minActiveBalance)
    {
        _setFundsGovernor(_governors[0]);
        _setConfigGovernor(_governors[1]);
        _setModulesGovernor(_governors[2]);
    }

    /**
    * @dev Fallback function allows to forward calls to a specific address in case it was previously registered
    *      Note the sender will be always the controller in case it is forwarded
    */
    function () external payable {
        address target = customFunctions[msg.sig];
        require(target != address(0), ERROR_CUSTOM_FUNCTION_NOT_SET);

        // solium-disable-next-line security/no-call-value
        (bool success,) = address(target).call.value(msg.value)(msg.data);
        assembly {
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            let result := success
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
    * @notice Change Court configuration params
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *        1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *        2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted guardians (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of guardian tokens that can be activated
    */
    function setConfig(
        uint64 _fromTermId,
        IERC20 _feeToken,
        uint256[3] calldata _fees,
        uint64[5] calldata _roundStateDurations,
        uint16[2] calldata _pcts,
        uint64[4] calldata _roundParams,
        uint256[2] calldata _appealCollateralParams,
        uint256 _minActiveBalance
    )
        external
        onlyConfigGovernor
    {
        uint64 currentTermId = _ensureCurrentTerm();
        _setConfig(
            currentTermId,
            _fromTermId,
            _feeToken,
            _fees,
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
        );
    }

    /**
    * @notice Delay the Court start time to `_newFirstTermStartTime`
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function delayStartTime(uint64 _newFirstTermStartTime) external onlyConfigGovernor {
        _delayStartTime(_newFirstTermStartTime);
    }

    /**
    * @notice Change funds governor address to `_newFundsGovernor`
    * @param _newFundsGovernor Address of the new funds governor to be set
    */
    function changeFundsGovernor(address _newFundsGovernor) external onlyFundsGovernor {
        require(_newFundsGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setFundsGovernor(_newFundsGovernor);
    }

    /**
    * @notice Change config governor address to `_newConfigGovernor`
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function changeConfigGovernor(address _newConfigGovernor) external onlyConfigGovernor {
        require(_newConfigGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setConfigGovernor(_newConfigGovernor);
    }

    /**
    * @notice Change modules governor address to `_newModulesGovernor`
    * @param _newModulesGovernor Address of the new governor to be set
    */
    function changeModulesGovernor(address _newModulesGovernor) external onlyModulesGovernor {
        require(_newModulesGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setModulesGovernor(_newModulesGovernor);
    }

    /**
    * @notice Remove the funds governor. Set the funds governor to the zero address.
    * @dev This action cannot be rolled back, once the funds governor has been unset, funds cannot be recovered from recoverable modules anymore
    */
    function ejectFundsGovernor() external onlyFundsGovernor {
        _setFundsGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Remove the modules governor. Set the modules governor to the zero address.
    * @dev This action cannot be rolled back, once the modules governor has been unset, system modules cannot be changed anymore
    */
    function ejectModulesGovernor() external onlyModulesGovernor {
        _setModulesGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Grant `_id` role to `_who`
    * @param _id ID of the role to be granted
    * @param _who Address to grant the role to
    */
    function grant(bytes32 _id, address _who) external onlyConfigGovernor {
        _grant(_id, _who);
    }

    /**
    * @notice Revoke `_id` role from `_who`
    * @param _id ID of the role to be revoked
    * @param _who Address to revoke the role from
    */
    function revoke(bytes32 _id, address _who) external onlyConfigGovernor {
        _revoke(_id, _who);
    }

    /**
    * @notice Freeze `_id` role
    * @param _id ID of the role to be frozen
    */
    function freeze(bytes32 _id) external onlyConfigGovernor {
        _freeze(_id);
    }

    /**
    * @notice Enact a bulk list of ACL operations
    */
    function bulk(BulkOp[] calldata _op, bytes32[] calldata _id, address[] calldata _who) external onlyConfigGovernor {
        _bulk(_op, _id, _who);
    }

    /**
    * @notice Set module `_id` to `_addr`
    * @param _id ID of the module to be set
    * @param _addr Address of the module to be set
    */
    function setModule(bytes32 _id, address _addr) external onlyModulesGovernor {
        _setModule(_id, _addr);
    }

    /**
    * @notice Set and link many modules at once
    * @param _newModuleIds List of IDs of the new modules to be set
    * @param _newModuleAddresses List of addresses of the new modules to be set
    * @param _newModuleLinks List of IDs of the modules that will be linked in the new modules being set
    * @param _currentModulesToBeSynced List of addresses of current modules to be re-linked to the new modules being set
    */
    function setModules(
        bytes32[] calldata _newModuleIds,
        address[] calldata _newModuleAddresses,
        bytes32[] calldata _newModuleLinks,
        address[] calldata _currentModulesToBeSynced
    )
        external
        onlyModulesGovernor
    {
        // We only care about the modules being set, links are optional
        require(_newModuleIds.length == _newModuleAddresses.length, ERROR_INVALID_IMPLS_INPUT_LENGTH);

        // First set the addresses of the new modules or the modules to be updated
        for (uint256 i = 0; i < _newModuleIds.length; i++) {
            _setModule(_newModuleIds[i], _newModuleAddresses[i]);
        }

        // Then sync the links of the new modules based on the list of IDs specified (ideally the IDs of their dependencies)
        _syncModuleLinks(_newModuleAddresses, _newModuleLinks);

        // Finally sync the links of the existing modules to be synced to the new modules being set
        _syncModuleLinks(_currentModulesToBeSynced, _newModuleIds);
    }

    /**
    * @notice Sync modules for a list of modules IDs based on their current implementation address
    * @param _modulesToBeSynced List of addresses of connected modules to be synced
    * @param _idsToBeSet List of IDs of the modules included in the sync
    */
    function syncModuleLinks(address[] calldata _modulesToBeSynced, bytes32[] calldata _idsToBeSet)
        external
        onlyModulesGovernor
    {
        require(_idsToBeSet.length > 0 && _modulesToBeSynced.length > 0, ERROR_INVALID_IMPLS_INPUT_LENGTH);
        _syncModuleLinks(_modulesToBeSynced, _idsToBeSet);
    }

    /**
    * @notice Disable module `_addr`
    * @dev Current modules can be disabled to allow pausing the court. However, these can be enabled back again, see `enableModule`
    * @param _addr Address of the module to be disabled
    */
    function disableModule(address _addr) external onlyModulesGovernor {
        Module storage module = allModules[_addr];
        _ensureModuleExists(module);
        require(!module.disabled, ERROR_MODULE_ALREADY_DISABLED);

        module.disabled = true;
        emit ModuleDisabled(module.id, _addr);
    }

    /**
    * @notice Enable module `_addr`
    * @param _addr Address of the module to be enabled
    */
    function enableModule(address _addr) external onlyModulesGovernor {
        Module storage module = allModules[_addr];
        _ensureModuleExists(module);
        require(module.disabled, ERROR_MODULE_ALREADY_ENABLED);

        module.disabled = false;
        emit ModuleEnabled(module.id, _addr);
    }

    /**
    * @notice Set custom function `_sig` for `_target`
    * @param _sig Signature of the function to be set
    * @param _target Address of the target implementation to be registered for the given signature
    */
    function setCustomFunction(bytes4 _sig, address _target) external onlyModulesGovernor {
        customFunctions[_sig] = _target;
        emit CustomFunctionSet(_sig, _target);
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. guardianFee Amount of fee tokens that is paid per guardian per dispute
    *         1. draftFee Amount of fee tokens per guardian to cover the drafting cost
    *         2. settleFee Amount of fee tokens per guardian to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundGuardiansNumber Number of guardians to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of guardians of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent guardian in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    */
    function getConfig(uint64 _termId) external view
        returns (
            IERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getConfigAt(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per guardian to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted guardian (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getDraftConfig(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of tokens guardians have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getMinActiveBalance(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the address of the funds governor
    * @return Address of the funds governor
    */
    function getFundsGovernor() external view returns (address) {
        return governor.funds;
    }

    /**
    * @dev Tell the address of the config governor
    * @return Address of the config governor
    */
    function getConfigGovernor() external view returns (address) {
        return governor.config;
    }

    /**
    * @dev Tell the address of the modules governor
    * @return Address of the modules governor
    */
    function getModulesGovernor() external view returns (address) {
        return governor.modules;
    }

    /**
    * @dev Tell if a given module is active
    * @param _id ID of the module to be checked
    * @param _addr Address of the module to be checked
    * @return True if the given module address has the requested ID and is enabled
    */
    function isActive(bytes32 _id, address _addr) external view returns (bool) {
        Module storage module = allModules[_addr];
        return module.id == _id && !module.disabled;
    }

    /**
    * @dev Tell the current ID and disable status of a module based on a given address
    * @param _addr Address of the requested module
    * @return id ID of the module being queried
    * @return disabled Whether the module has been disabled
    */
    function getModuleByAddress(address _addr) external view returns (bytes32 id, bool disabled) {
        Module storage module = allModules[_addr];
        id = module.id;
        disabled = module.disabled;
    }

    /**
    * @dev Tell the current address and disable status of a module based on a given ID
    * @param _id ID of the module being queried
    * @return addr Current address of the requested module
    * @return disabled Whether the module has been disabled
    */
    function getModule(bytes32 _id) external view returns (address addr, bool disabled) {
        return _getModule(_id);
    }

    /**
    * @dev Tell the information for the current DisputeManager module
    * @return addr Current address of the DisputeManager module
    * @return disabled Whether the module has been disabled
    */
    function getDisputeManager() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_DISPUTE_MANAGER);
    }

    /**
    * @dev Tell the information for  the current GuardiansRegistry module
    * @return addr Current address of the GuardiansRegistry module
    * @return disabled Whether the module has been disabled
    */
    function getGuardiansRegistry() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_GUARDIANS_REGISTRY);
    }

    /**
    * @dev Tell the information for the current Voting module
    * @return addr Current address of the Voting module
    * @return disabled Whether the module has been disabled
    */
    function getVoting() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_VOTING);
    }

    /**
    * @dev Tell the information for the current PaymentsBook module
    * @return addr Current address of the PaymentsBook module
    * @return disabled Whether the module has been disabled
    */
    function getPaymentsBook() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_PAYMENTS_BOOK);
    }

    /**
    * @dev Tell the information for the current Treasury module
    * @return addr Current address of the Treasury module
    * @return disabled Whether the module has been disabled
    */
    function getTreasury() external view returns (address addr, bool disabled) {
        return _getModule(MODULE_ID_TREASURY);
    }

    /**
    * @dev Tell the target registered for a custom function
    * @param _sig Signature of the function being queried
    * @return Address of the target where the function call will be forwarded
    */
    function getCustomFunction(bytes4 _sig) external view returns (address) {
        return customFunctions[_sig];
    }

    /**
    * @dev Internal function to set the address of the funds governor
    * @param _newFundsGovernor Address of the new config governor to be set
    */
    function _setFundsGovernor(address _newFundsGovernor) internal {
        emit FundsGovernorChanged(governor.funds, _newFundsGovernor);
        governor.funds = _newFundsGovernor;
    }

    /**
    * @dev Internal function to set the address of the config governor
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function _setConfigGovernor(address _newConfigGovernor) internal {
        emit ConfigGovernorChanged(governor.config, _newConfigGovernor);
        governor.config = _newConfigGovernor;
    }

    /**
    * @dev Internal function to set the address of the modules governor
    * @param _newModulesGovernor Address of the new modules governor to be set
    */
    function _setModulesGovernor(address _newModulesGovernor) internal {
        emit ModulesGovernorChanged(governor.modules, _newModulesGovernor);
        governor.modules = _newModulesGovernor;
    }

    /**
    * @dev Internal function to set an address as the current implementation for a module
    *      Note that the disabled condition is not affected, if the module was not set before it will be enabled by default
    * @param _id Id of the module to be set
    * @param _addr Address of the module to be set
    */
    function _setModule(bytes32 _id, address _addr) internal {
        require(isContract(_addr), ERROR_IMPLEMENTATION_NOT_CONTRACT);

        currentModules[_id] = _addr;
        allModules[_addr].id = _id;
        emit ModuleSet(_id, _addr);
    }

    /**
    * @dev Internal function to sync the modules for a list of modules IDs based on their current implementation address
    * @param _modulesToBeSynced List of addresses of connected modules to be synced
    * @param _idsToBeSet List of IDs of the modules to be linked
    */
    function _syncModuleLinks(address[] memory _modulesToBeSynced, bytes32[] memory _idsToBeSet) internal {
        address[] memory addressesToBeSet = new address[](_idsToBeSet.length);

        // Load the addresses associated with the requested module ids
        for (uint256 i = 0; i < _idsToBeSet.length; i++) {
            address moduleAddress = _getModuleAddress(_idsToBeSet[i]);
            Module storage module = allModules[moduleAddress];
            _ensureModuleExists(module);
            addressesToBeSet[i] = moduleAddress;
        }

        // Update the links of all the requested modules
        for (uint256 j = 0; j < _modulesToBeSynced.length; j++) {
            IModulesLinker(_modulesToBeSynced[j]).linkModules(_idsToBeSet, addressesToBeSet);
        }
    }

    /**
    * @dev Internal function to notify when a term has been transitioned
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal {
        _ensureTermConfig(_termId);
    }

    /**
    * @dev Internal function to check if a module was set
    * @param _module Module to be checked
    */
    function _ensureModuleExists(Module storage _module) internal view {
        require(_module.id != bytes32(0), ERROR_MODULE_NOT_SET);
    }

    /**
    * @dev Internal function to tell the information for a module based on a given ID
    * @param _id ID of the module being queried
    * @return addr Current address of the requested module
    * @return disabled Whether the module has been disabled
    */
    function _getModule(bytes32 _id) internal view returns (address addr, bool disabled) {
        addr = _getModuleAddress(_id);
        disabled = _isModuleDisabled(addr);
    }

    /**
    * @dev Tell the current address for a module by ID
    * @param _id ID of the module being queried
    * @return Current address of the requested module
    */
    function _getModuleAddress(bytes32 _id) internal view returns (address) {
        return currentModules[_id];
    }

    /**
    * @dev Tell whether a module is disabled
    * @param _addr Address of the module being queried
    * @return True if the module is disabled, false otherwise
    */
    function _isModuleDisabled(address _addr) internal view returns (bool) {
        return allModules[_addr].disabled;
    }
}

contract ConfigConsumer is CourtConfigData {
    /**
    * @dev Internal function to fetch the address of the Config module from the controller
    * @return Address of the Config module
    */
    function _courtConfig() internal view returns (IConfig);

    /**
    * @dev Internal function to get the Court config for a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return Court config for the given term
    */
    function _getConfigAt(uint64 _termId) internal view returns (Config memory) {
        (IERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance) = _courtConfig().getConfig(_termId);

        Config memory config;

        config.fees = FeesConfig({
            token: _feeToken,
            guardianFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            evidenceTerms: _roundStateDurations[0],
            commitTerms: _roundStateDurations[1],
            revealTerms: _roundStateDurations[2],
            appealTerms: _roundStateDurations[3],
            appealConfirmTerms: _roundStateDurations[4],
            penaltyPct: _pcts[0],
            firstRoundGuardiansNumber: _roundParams[0],
            appealStepFactor: _roundParams[1],
            maxRegularAppealRounds: _roundParams[2],
            finalRoundLockTerms: _roundParams[3],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.minActiveBalance = _minActiveBalance;

        return config;
    }

    /**
    * @dev Internal function to get the draft config for a given term
    * @param _termId Identification number of the term querying the draft config of
    * @return Draft config for the given term
    */
    function _getDraftConfig(uint64 _termId) internal view returns (DraftConfig memory) {
        (IERC20 feeToken, uint256 draftFee, uint16 penaltyPct) = _courtConfig().getDraftConfig(_termId);
        return DraftConfig({ feeToken: feeToken, draftFee: draftFee, penaltyPct: penaltyPct });
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of guardian tokens that can be activated
    */
    function _getMinActiveBalance(uint64 _termId) internal view returns (uint256) {
        return _courtConfig().getMinActiveBalance(_termId);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface ITreasury {
    /**
    * @dev Assign a certain amount of tokens to an account
    * @param _token ERC20 token to be assigned
    * @param _to Address of the recipient that will be assigned the tokens to
    * @param _amount Amount of tokens to be assigned to the recipient
    */
    function assign(IERC20 _token, address _to, uint256 _amount) external;

    /**
    * @dev Withdraw a certain amount of tokens
    * @param _token ERC20 token to be withdrawn
    * @param _from Address withdrawing the tokens from
    * @param _to Address of the recipient that will receive the tokens
    * @param _amount Amount of tokens to be withdrawn from the sender
    */
    function withdraw(IERC20 _token, address _from, address _to, uint256 _amount) external;
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface IGuardiansRegistry {

    /**
    * @dev Assign a requested amount of guardian tokens to a guardian
    * @param _guardian Guardian to add an amount of tokens to
    * @param _amount Amount of tokens to be added to the available balance of a guardian
    */
    function assignTokens(address _guardian, uint256 _amount) external;

    /**
    * @dev Burn a requested amount of guardian tokens
    * @param _amount Amount of tokens to be burned
    */
    function burnTokens(uint256 _amount) external;

    /**
    * @dev Draft a set of guardians based on given requirements for a term id
    * @param _params Array containing draft requirements:
    *        0. bytes32 Term randomness
    *        1. uint256 Dispute id
    *        2. uint64  Current term id
    *        3. uint256 Number of seats already filled
    *        4. uint256 Number of seats left to be filled
    *        5. uint64  Number of guardians required for the draft
    *        6. uint16  Permyriad of the minimum active balance to be locked for the draft
    *
    * @return guardians List of guardians selected for the draft
    * @return length Size of the list of the draft result
    */
    function draft(uint256[7] calldata _params) external returns (address[] memory guardians, uint256 length);

    /**
    * @dev Slash a set of guardians based on their votes compared to the winning ruling
    * @param _termId Current term id
    * @param _guardians List of guardian addresses to be slashed
    * @param _lockedAmounts List of amounts locked for each corresponding guardian that will be either slashed or returned
    * @param _rewardedGuardians List of booleans to tell whether a guardian's active balance has to be slashed or not
    * @return Total amount of slashed tokens
    */
    function slashOrUnlock(uint64 _termId, address[] calldata _guardians, uint256[] calldata _lockedAmounts, bool[] calldata _rewardedGuardians)
        external
        returns (uint256 collectedTokens);

    /**
    * @dev Try to collect a certain amount of tokens from a guardian for the next term
    * @param _guardian Guardian to collect the tokens from
    * @param _amount Amount of tokens to be collected from the given guardian and for the requested term id
    * @param _termId Current term id
    * @return True if the guardian has enough unlocked tokens to be collected for the requested term, false otherwise
    */
    function collectTokens(address _guardian, uint256 _amount, uint64 _termId) external returns (bool);

    /**
    * @dev Lock a guardian's withdrawals until a certain term ID
    * @param _guardian Address of the guardian to be locked
    * @param _termId Term ID until which the guardian's withdrawals will be locked
    */
    function lockWithdrawals(address _guardian, uint64 _termId) external;

    /**
    * @dev Tell the active balance of a guardian for a given term id
    * @param _guardian Address of the guardian querying the active balance of
    * @param _termId Term ID querying the active balance for
    * @return Amount of active tokens for guardian in the requested past term id
    */
    function activeBalanceOfAt(address _guardian, uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell the total amount of active guardian tokens at the given term id
    * @param _termId Term ID querying the total active balance for
    * @return Total amount of active guardian tokens at the given term id
    */
    function totalActiveBalanceAt(uint64 _termId) external view returns (uint256);
}

/*
 * SPDX-License-Identifier:    MIT
 */
interface IPaymentsBook {
    /**
    * @dev Pay an amount of tokens
    * @param _token Address of the token being paid
    * @param _amount Amount of tokens being paid
    * @param _payer Address paying on behalf of
    * @param _data Optional data
    */
    function pay(address _token, uint256 _amount, address _payer, bytes calldata _data) external payable;
}

contract Controlled is IModulesLinker, IsContract, ModuleIds, ConfigConsumer {
    string private constant ERROR_MODULE_NOT_SET = "CTD_MODULE_NOT_SET";
    string private constant ERROR_INVALID_MODULES_LINK_INPUT = "CTD_INVALID_MODULES_LINK_INPUT";
    string private constant ERROR_CONTROLLER_NOT_CONTRACT = "CTD_CONTROLLER_NOT_CONTRACT";
    string private constant ERROR_SENDER_NOT_ALLOWED = "CTD_SENDER_NOT_ALLOWED";
    string private constant ERROR_SENDER_NOT_CONTROLLER = "CTD_SENDER_NOT_CONTROLLER";
    string private constant ERROR_SENDER_NOT_CONFIG_GOVERNOR = "CTD_SENDER_NOT_CONFIG_GOVERNOR";
    string private constant ERROR_SENDER_NOT_ACTIVE_VOTING = "CTD_SENDER_NOT_ACTIVE_VOTING";
    string private constant ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER = "CTD_SEND_NOT_ACTIVE_DISPUTE_MGR";
    string private constant ERROR_SENDER_NOT_CURRENT_DISPUTE_MANAGER = "CTD_SEND_NOT_CURRENT_DISPUTE_MGR";

    // Address of the controller
    Controller public controller;

    // List of modules linked indexed by ID
    mapping (bytes32 => address) public linkedModules;

    event ModuleLinked(bytes32 id, address addr);

    /**
    * @dev Ensure the msg.sender is the controller's config governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == _configGovernor(), ERROR_SENDER_NOT_CONFIG_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the controller
    */
    modifier onlyController() {
        require(msg.sender == address(controller), ERROR_SENDER_NOT_CONTROLLER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is an active DisputeManager module
    */
    modifier onlyActiveDisputeManager() {
        require(controller.isActive(MODULE_ID_DISPUTE_MANAGER, msg.sender), ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the current DisputeManager module
    */
    modifier onlyCurrentDisputeManager() {
        (address addr, bool disabled) = controller.getDisputeManager();
        require(msg.sender == addr, ERROR_SENDER_NOT_CURRENT_DISPUTE_MANAGER);
        require(!disabled, ERROR_SENDER_NOT_ACTIVE_DISPUTE_MANAGER);
        _;
    }

    /**
    * @dev Ensure the msg.sender is an active Voting module
    */
    modifier onlyActiveVoting() {
        require(controller.isActive(MODULE_ID_VOTING, msg.sender), ERROR_SENDER_NOT_ACTIVE_VOTING);
        _;
    }

    /**
    * @dev This modifier will check that the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    */
    modifier authenticateSender(address _user) {
        _authenticateSender(_user);
        _;
    }

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    */
    constructor(Controller _controller) public {
        require(isContract(address(_controller)), ERROR_CONTROLLER_NOT_CONTRACT);
        controller = _controller;
    }

    /**
    * @notice Update the implementation links of a list of modules
    * @dev The controller is expected to ensure the given addresses are correct modules
    * @param _ids List of IDs of the modules to be updated
    * @param _addresses List of module addresses to be updated
    */
    function linkModules(bytes32[] calldata _ids, address[] calldata _addresses) external onlyController {
        require(_ids.length == _addresses.length, ERROR_INVALID_MODULES_LINK_INPUT);

        for (uint256 i = 0; i < _ids.length; i++) {
            linkedModules[_ids[i]] = _addresses[i];
            emit ModuleLinked(_ids[i], _addresses[i]);
        }
    }

    /**
    * @dev Internal function to ensure the Court term is up-to-date, it will try to update it if not
    * @return Identification number of the current Court term
    */
    function _ensureCurrentTerm() internal returns (uint64) {
        return _clock().ensureCurrentTerm();
    }

    /**
    * @dev Internal function to fetch the last ensured term ID of the Court
    * @return Identification number of the last ensured term
    */
    function _getLastEnsuredTermId() internal view returns (uint64) {
        return _clock().getLastEnsuredTermId();
    }

    /**
    * @dev Internal function to tell the current term identification number
    * @return Identification number of the current term
    */
    function _getCurrentTermId() internal view returns (uint64) {
        return _clock().getCurrentTermId();
    }

    /**
    * @dev Internal function to fetch the controller's config governor
    * @return Address of the controller's config governor
    */
    function _configGovernor() internal view returns (address) {
        return controller.getConfigGovernor();
    }

    /**
    * @dev Internal function to fetch the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function _disputeManager() internal view returns (IDisputeManager) {
        return IDisputeManager(_getLinkedModule(MODULE_ID_DISPUTE_MANAGER));
    }

    /**
    * @dev Internal function to fetch the address of the GuardianRegistry module implementation
    * @return Address of the GuardianRegistry module implementation
    */
    function _guardiansRegistry() internal view returns (IGuardiansRegistry) {
        return IGuardiansRegistry(_getLinkedModule(MODULE_ID_GUARDIANS_REGISTRY));
    }

    /**
    * @dev Internal function to fetch the address of the Voting module implementation
    * @return Address of the Voting module implementation
    */
    function _voting() internal view returns (ICRVoting) {
        return ICRVoting(_getLinkedModule(MODULE_ID_VOTING));
    }

    /**
    * @dev Internal function to fetch the address of the PaymentsBook module implementation
    * @return Address of the PaymentsBook module implementation
    */
    function _paymentsBook() internal view returns (IPaymentsBook) {
        return IPaymentsBook(_getLinkedModule(MODULE_ID_PAYMENTS_BOOK));
    }

    /**
    * @dev Internal function to fetch the address of the Treasury module implementation
    * @return Address of the Treasury module implementation
    */
    function _treasury() internal view returns (ITreasury) {
        return ITreasury(_getLinkedModule(MODULE_ID_TREASURY));
    }

    /**
    * @dev Internal function to tell the address linked for a module based on a given ID
    * @param _id ID of the module being queried
    * @return Linked address of the requested module
    */
    function _getLinkedModule(bytes32 _id) internal view returns (address) {
        address module = linkedModules[_id];
        require(module != address(0), ERROR_MODULE_NOT_SET);
        return module;
    }

    /**
    * @dev Internal function to fetch the address of the Clock module from the controller
    * @return Address of the Clock module
    */
    function _clock() internal view returns (IClock) {
        return IClock(controller);
    }

    /**
    * @dev Internal function to fetch the address of the Config module from the controller
    * @return Address of the Config module
    */
    function _courtConfig() internal view returns (IConfig) {
        return IConfig(controller);
    }

    /**
    * @dev Ensure that the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    */
    function _authenticateSender(address _user) internal view {
        require(_isSenderAllowed(_user), ERROR_SENDER_NOT_ALLOWED);
    }

    /**
    * @dev Tell whether the sender is the user to act on behalf of or someone with the required permission
    * @param _user Address of the user to act on behalf of
    * @return True if the sender is the user to act on behalf of or someone with the required permission, false otherwise
    */
    function _isSenderAllowed(address _user) internal view returns (bool) {
        return msg.sender == _user || _hasRole(msg.sender);
    }

    /**
    * @dev Tell whether an address holds the required permission to access the requested functionality
    * @param _addr Address being checked
    * @return True if the given address has the required permission to access the requested functionality, false otherwise
    */
    function _hasRole(address _addr) internal view returns (bool) {
        bytes32 roleId = keccak256(abi.encodePacked(address(this), msg.sig));
        return controller.hasRole(_addr, roleId);
    }
}

contract CRVoting is ICRVoting, Controlled {
    using SafeMath for uint256;

    string private constant ERROR_VOTE_ALREADY_EXISTS = "CRV_VOTE_ALREADY_EXISTS";
    string private constant ERROR_VOTE_DOES_NOT_EXIST = "CRV_VOTE_DOES_NOT_EXIST";
    string private constant ERROR_VOTE_ALREADY_COMMITTED = "CRV_VOTE_ALREADY_COMMITTED";
    string private constant ERROR_VOTE_ALREADY_REVEALED = "CRV_VOTE_ALREADY_REVEALED";
    string private constant ERROR_SENDER_NOT_DELEGATE = "CRV_SENDER_NOT_DELEGATE";
    string private constant ERROR_INVALID_OUTCOME = "CRV_INVALID_OUTCOME";
    string private constant ERROR_INVALID_OUTCOMES_AMOUNT = "CRV_INVALID_OUTCOMES_AMOUNT";
    string private constant ERROR_INVALID_COMMITMENT_SALT = "CRV_INVALID_COMMITMENT_SALT";

    // Outcome nr. 0 is used to denote a missing vote (default)
    uint8 internal constant OUTCOME_MISSING = uint8(0);
    // Outcome nr. 1 is used to denote a leaked vote
    uint8 internal constant OUTCOME_LEAKED = uint8(1);
    // Outcome nr. 2 is used to denote a refused vote
    uint8 internal constant OUTCOME_REFUSED = uint8(2);
    // Besides the options listed above, every vote instance must provide at least 2 outcomes
    uint8 internal constant MIN_POSSIBLE_OUTCOMES = uint8(2);
    // Max number of outcomes excluding the default ones
    uint8 internal constant MAX_POSSIBLE_OUTCOMES = uint8(-1) - 3;

    struct CastVote {
        bytes32 commitment;                         // Hash of the outcome casted by the voter
        uint8 outcome;                              // Outcome submitted by the voter
    }

    struct Vote {
        uint8 winningOutcome;                       // Outcome winner of a vote instance
        uint8 maxAllowedOutcome;                    // Highest outcome allowed for the vote instance
        mapping (address => CastVote) votes;        // Mapping of voters addresses to their casted votes
        mapping (uint8 => uint256) outcomesTally;   // Tally for each of the possible outcomes
    }

    // Vote records indexed by their ID
    mapping (uint256 => Vote) internal voteRecords;
    // Delegates indexed by principals
    mapping (address => address) internal delegates;

    event VotingCreated(uint256 indexed voteId, uint8 possibleOutcomes);
    event VoteCommitted(uint256 indexed voteId, address indexed voter, bytes32 commitment);
    event VoteRevealed(uint256 indexed voteId, address indexed voter, uint8 outcome);
    event VoteLeaked(uint256 indexed voteId, address indexed voter, uint8 outcome);
    event DelegateSet(address indexed voter, address delegate);

    /**
    * @dev Ensure a certain vote exists
    * @param _voteId ID of the vote instance to be checked
    */
    modifier voteExists(uint256 _voteId) {
        require(_existsVote(_voteId), ERROR_VOTE_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Constructor function
    * @param _controller Address of the controller
    */
    constructor(Controller _controller) Controlled(_controller) public {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
    * @notice Set `_delegate` as the delegate for `_voter`
    * @param _voter Address of the voter updating the delegate for
    * @param _delegate Address of the delegate to be set
    */
    function delegate(address _voter, address _delegate) external authenticateSender(_voter) {
        delegates[_voter] = _delegate;
        emit DelegateSet(_voter, _delegate);
    }

    /**
    * @notice Create a new vote instance with ID #`_voteId` and `_possibleOutcomes` possible outcomes
    * @dev This function can only be called by the CRVoting owner
    * @param _voteId ID of the new vote instance to be created
    * @param _possibleOutcomes Number of possible outcomes for the new vote instance to be created
    */
    function createVote(uint256 _voteId, uint8 _possibleOutcomes) external onlyCurrentDisputeManager {
        require(_possibleOutcomes >= MIN_POSSIBLE_OUTCOMES && _possibleOutcomes <= MAX_POSSIBLE_OUTCOMES, ERROR_INVALID_OUTCOMES_AMOUNT);
        require(!_existsVote(_voteId), ERROR_VOTE_ALREADY_EXISTS);

        // No need for SafeMath: we already checked the number of outcomes above
        Vote storage vote = voteRecords[_voteId];
        vote.maxAllowedOutcome = OUTCOME_REFUSED + _possibleOutcomes;
        emit VotingCreated(_voteId, _possibleOutcomes);
    }

    /**
    * @notice Commit a vote for `_voter` on vote #`_voteId`
    * @param _voteId ID of the vote instance to commit a vote to
    * @param _voter Address of the voter to commit a vote for
    * @param _commitment Hashed outcome to be stored for future reveal
    */
    function commit(uint256 _voteId, address _voter, bytes32 _commitment) external voteExists(_voteId) {
        bool isSenderAllowed = _isDelegateOf(_voter, msg.sender) || _isSenderAllowed(_voter);
        require(isSenderAllowed, ERROR_SENDER_NOT_DELEGATE);

        CastVote storage castVote = voteRecords[_voteId].votes[_voter];
        require(castVote.commitment == bytes32(0), ERROR_VOTE_ALREADY_COMMITTED);
        _ensureVoterCanCommit(_voteId, _voter);

        castVote.commitment = _commitment;
        emit VoteCommitted(_voteId, _voter, _commitment);
    }

    /**
    * @notice Leak `_outcome` vote of `_voter` for vote #`_voteId`
    * @param _voteId ID of the vote instance to leak a vote of
    * @param _voter Address of the voter to leak a vote of
    * @param _outcome Outcome leaked for the voter
    * @param _salt Salt to decrypt and validate the committed vote of the voter
    */
    function leak(uint256 _voteId, address _voter, uint8 _outcome, bytes32 _salt) external voteExists(_voteId) {
        CastVote storage castVote = voteRecords[_voteId].votes[_voter];
        _checkValidSalt(castVote, _outcome, _salt);
        _ensureCanCommit(_voteId);

        // There is no need to check if an outcome is valid if it was leaked.
        // Additionally, leaked votes are not considered for the tally.
        castVote.outcome = OUTCOME_LEAKED;
        emit VoteLeaked(_voteId, _voter, _outcome);
    }

    /**
    * @notice Reveal `_outcome` vote of `_voter` for vote #`_voteId`
    * @param _voteId ID of the vote instance to reveal a vote of
    * @param _voter Address of the voter to reveal a vote for
    * @param _outcome Outcome revealed by the voter
    * @param _salt Salt to decrypt and validate the committed vote of the voter
    */
    function reveal(uint256 _voteId, address _voter, uint8 _outcome, bytes32 _salt) external voteExists(_voteId) {
        Vote storage vote = voteRecords[_voteId];
        CastVote storage castVote = vote.votes[_voter];
        _checkValidSalt(castVote, _outcome, _salt);
        require(_isValidOutcome(vote, _outcome), ERROR_INVALID_OUTCOME);

        uint256 weight = _ensureVoterCanReveal(_voteId, _voter);

        castVote.outcome = _outcome;
        _updateTally(vote, _outcome, weight);
        emit VoteRevealed(_voteId, _voter, _outcome);
    }

    /**
    * @dev Tell if a delegate currently represents another voter
    * @param _voter Address of the principal being queried
    * @param _delegate Address of the delegate being queried
    * @return True if the given delegate currently represents the voter
    */
    function isDelegateOf(address _voter, address _delegate) external view returns (bool) {
        return _isDelegateOf(_voter, _delegate);
    }

    /**
    * @dev Get the maximum allowed outcome for a given vote instance
    * @param _voteId ID of the vote instance querying the max allowed outcome of
    * @return Max allowed outcome for the given vote instance
    */
    function getMaxAllowedOutcome(uint256 _voteId) external view voteExists(_voteId) returns (uint8) {
        Vote storage vote = voteRecords[_voteId];
        return vote.maxAllowedOutcome;
    }

    /**
    * @dev Get the winning outcome of a vote instance. If the winning outcome is missing, which means no one voted in
    *      the given vote instance, it will be considered refused.
    * @param _voteId ID of the vote instance querying the winning outcome of
    * @return Winning outcome of the given vote instance or refused in case it's missing
    */
    function getWinningOutcome(uint256 _voteId) external view voteExists(_voteId) returns (uint8) {
        Vote storage vote = voteRecords[_voteId];
        uint8 winningOutcome = vote.winningOutcome;
        return winningOutcome == OUTCOME_MISSING ? OUTCOME_REFUSED : winningOutcome;
    }

    /**
    * @dev Get the tally of an outcome for a certain vote instance
    * @param _voteId ID of the vote instance querying the tally of
    * @param _outcome Outcome querying the tally of
    * @return Tally of the outcome being queried for the given vote instance
    */
    function getOutcomeTally(uint256 _voteId, uint8 _outcome) external view voteExists(_voteId) returns (uint256) {
        Vote storage vote = voteRecords[_voteId];
        return vote.outcomesTally[_outcome];
    }

    /**
    * @dev Tell whether an outcome is valid for a given vote instance or not. Missing and leaked outcomes are not considered
    *      valid. The only valid outcomes are refused or any of the custom outcomes of the given vote instance.
    * @param _voteId ID of the vote instance to check the outcome of
    * @param _outcome Outcome to check if valid or not
    * @return True if the given outcome is valid for the requested vote instance, false otherwise.
    */
    function isValidOutcome(uint256 _voteId, uint8 _outcome) external view voteExists(_voteId) returns (bool) {
        Vote storage vote = voteRecords[_voteId];
        return _isValidOutcome(vote, _outcome);
    }

    /**
    * @dev Get the outcome voted by a voter for a certain vote instance
    * @param _voteId ID of the vote instance querying the outcome of
    * @param _voter Address of the voter querying the outcome of
    * @return Outcome of the voter for the given vote instance
    */
    function getVoterOutcome(uint256 _voteId, address _voter) external view voteExists(_voteId) returns (uint8) {
        Vote storage vote = voteRecords[_voteId];
        return vote.votes[_voter].outcome;
    }

    /**
    * @dev Tell whether a voter voted in favor of a certain outcome in a vote instance or not.
    * @param _voteId ID of the vote instance to query if a voter voted in favor of a certain outcome
    * @param _outcome Outcome to query if the given voter voted in favor of
    * @param _voter Address of the voter to query if voted in favor of the given outcome
    * @return True if the given voter voted in favor of the given outcome, false otherwise
    */
    function hasVotedInFavorOf(uint256 _voteId, uint8 _outcome, address _voter) external view voteExists(_voteId) returns (bool) {
        Vote storage vote = voteRecords[_voteId];
        return vote.votes[_voter].outcome == _outcome;
    }

    /**
    * @dev Filter a list of voters based on whether they voted in favor of a certain outcome in a vote instance or not.
    *      Note that if there was no winning outcome, it means that no one voted, then all voters will be considered
    *      voting against any of the given outcomes.
    * @param _voteId ID of the vote instance to be checked
    * @param _outcome Outcome to filter the list of voters of
    * @param _voters List of addresses of the voters to be filtered
    * @return List of results to tell whether a voter voted in favor of the given outcome or not
    */
    function getVotersInFavorOf(uint256 _voteId, uint8 _outcome, address[] calldata _voters) external view voteExists(_voteId)
        returns (bool[] memory)
    {
        Vote storage vote = voteRecords[_voteId];
        bool[] memory votersInFavor = new bool[](_voters.length);

        // If there was a winning outcome, filter those voters that voted in favor of the given outcome.
        for (uint256 i = 0; i < _voters.length; i++) {
            votersInFavor[i] = _outcome == vote.votes[_voters[i]].outcome;
        }
        return votersInFavor;
    }

    /**
    * @dev Hash a vote outcome using a given salt
    * @param _outcome Outcome to be hashed
    * @param _salt Encryption salt
    * @return Hashed outcome
    */
    function hashVote(uint8 _outcome, bytes32 _salt) external pure returns (bytes32) {
        return _hashVote(_outcome, _salt);
    }

    /**
    * @dev Internal function to ensure votes can be committed for a vote
    * @param _voteId ID of the vote instance to be checked
    */
    function _ensureCanCommit(uint256 _voteId) internal {
        ICRVotingOwner owner = _votingOwner();
        owner.ensureCanCommit(_voteId);
    }

    /**
    * @dev Internal function to ensure a voter can commit votes
    * @param _voteId ID of the vote instance to be checked
    * @param _voter Address of the voter willing to commit a vote
    */
    function _ensureVoterCanCommit(uint256 _voteId, address _voter) internal {
        ICRVotingOwner owner = _votingOwner();
        owner.ensureCanCommit(_voteId, _voter);
    }

    /**
    * @dev Internal function to ensure a voter can reveal votes
    * @param _voteId ID of the vote instance to be checked
    * @param _voter Address of the voter willing to reveal a vote
    * @return Weight of the voter willing to reveal a vote
    */
    function _ensureVoterCanReveal(uint256 _voteId, address _voter) internal returns (uint256) {
        // There's no need to check voter weight, as this was done on commit
        ICRVotingOwner owner = _votingOwner();
        uint64 weight = owner.ensureCanReveal(_voteId, _voter);
        return uint256(weight);
    }

    /**
    * @dev Internal function to fetch the address of the Voting module's owner
    * @return Address of the Voting module's owner
    */
    function _votingOwner() internal view returns (ICRVotingOwner) {
        return ICRVotingOwner(address(_disputeManager()));
    }

    /**
    * @dev Internal function to check if a vote can be revealed for the given outcome and salt
    * @param _castVote Cast vote to be revealed
    * @param _outcome Outcome of the cast vote to be proved
    * @param _salt Salt to decrypt and validate the provided outcome for a cast vote
    */
    function _checkValidSalt(CastVote storage _castVote, uint8 _outcome, bytes32 _salt) internal view {
        require(_castVote.outcome == OUTCOME_MISSING, ERROR_VOTE_ALREADY_REVEALED);
        require(_castVote.commitment == _hashVote(_outcome, _salt), ERROR_INVALID_COMMITMENT_SALT);
    }

    /**
    * @dev Internal function to tell whether a certain outcome is valid for a given vote instance or not. Note that
    *      the missing and leaked outcomes are not considered valid. The only outcomes considered valid are refused
    *      or any of the possible outcomes of the given vote instance. This function assumes the given vote exists.
    * @param _vote Vote instance to check the outcome of
    * @param _outcome Outcome to check if valid or not
    * @return True if the given outcome is valid for the requested vote instance, false otherwise.
    */
    function _isValidOutcome(Vote storage _vote, uint8 _outcome) internal view returns (bool) {
        return _outcome >= OUTCOME_REFUSED && _outcome <= _vote.maxAllowedOutcome;
    }

    /**
    * @dev Internal function to check if a vote instance was already created
    * @param _voteId ID of the vote instance to be checked
    * @return True if the given vote instance was already created, false otherwise
    */
    function _existsVote(uint256 _voteId) internal view returns (bool) {
        Vote storage vote = voteRecords[_voteId];
        return vote.maxAllowedOutcome != OUTCOME_MISSING;
    }

    /**
    * @dev Tell if a delegates represents another voter
    * @param _voter Address of the principal being queried
    * @param _delegate Address of the delegate being queried
    * @return True if the given delegate currently represents the voter
    */
    function _isDelegateOf(address _voter, address _delegate) internal view returns (bool) {
        return _voter == _delegate || delegates[_voter] == _delegate;
    }

    /**
    * @dev Internal function to hash a vote outcome using a given salt
    * @param _outcome Outcome to be hashed
    * @param _salt Encryption salt
    * @return Hashed outcome
    */
    function _hashVote(uint8 _outcome, bytes32 _salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_outcome, _salt));
    }

    /**
    * @dev Tell chain ID
    * @return chainId Chain ID
    */
    function _chainId() internal pure returns (uint256 chainId) {
        assembly { chainId := chainid() }
    }

    /**
    * @dev Private function to update the tally of a given vote instance based on a new weight in favor of an outcome.
    *      This function assumes the vote instance exists.
    * @param _vote Vote instance to update the tally of
    * @param _outcome Outcome of the vote instance to update the tally of
    * @param _weight Weight to be added to the given outcome of the vote instance
    */
    function _updateTally(Vote storage _vote, uint8 _outcome, uint256 _weight) private {
        // Check if the given outcome is valid. Missing and leaked votes are ignored for the tally.
        if (!_isValidOutcome(_vote, _outcome)) {
            return;
        }

        uint256 newOutcomeTally = _vote.outcomesTally[_outcome].add(_weight);
        _vote.outcomesTally[_outcome] = newOutcomeTally;

        // Update the winning outcome only if its support was passed or if the given outcome represents a lowest
        // option than the winning outcome in case of a tie.
        uint8 winningOutcome = _vote.winningOutcome;
        uint256 winningOutcomeTally = _vote.outcomesTally[winningOutcome];
        if (newOutcomeTally > winningOutcomeTally || (newOutcomeTally == winningOutcomeTally && _outcome < winningOutcome)) {
            _vote.winningOutcome = _outcome;
        }
    }
}