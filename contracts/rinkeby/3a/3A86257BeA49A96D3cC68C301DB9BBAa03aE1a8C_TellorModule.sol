// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "usingtellor/contracts/UsingTellor.sol";

contract TellorModule is Module, UsingTellor {
    // Events
    event ProposalQuestionCreated(
        bytes32 indexed questionId,
        string indexed proposalId
    );

    event TellorModuleSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );

    // Storage
    uint32 public answerExpiration;
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );

    // Mapping of questionHash to transactionHash to execution state
    mapping(bytes32 => mapping(bytes32 => bool))
        public executedProposalTransactions;

    bytes32 public constant INVALIDATED =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint32 public questionCooldown;

    // Mapping of question hash to question id. Special case: INVALIDATED for question hashes that have been invalidated
    mapping(bytes32 => bytes32) public questionIds;

    bytes32 public constant TRANSACTION_TYPEHASH =
        0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

    // keccak256(
    //     "Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)"
    // );

    /*Functions*/
    /**
     * @param _owner Address of the owner
     * @param _avatar Address of the avatar (e.g. a Safe)
     * @param _target Address of the contract that will call exec function
     * @param _tellorAddress Address of the Tellor oracle contract
     * @param _cooldown Cooldown in seconds that should be required after a oracle provided answer
     * @param _expiration Duration that a positive answer of the oracle is valid in seconds (or 0 if valid forever)
     * @notice There need to be at least 60 seconds between end of cooldown and expiration
     */
    constructor(
        address _owner,
        address _avatar,
        address _target,
        address payable _tellorAddress,
        uint32 _cooldown,
        uint32 _expiration
    ) UsingTellor(_tellorAddress) {
        bytes memory initParams = abi.encode(
            _owner,
            _avatar,
            _target,
            _cooldown,
            _expiration
        );
        setUp(initParams);
    }

    function addProposal(string memory _proposalId, bytes32[] memory _txHashes)
        public
    {
        _addProposalWithNonce(_proposalId, _txHashes, 0);
    }

    /**
     * @dev Build the question by combining the proposalId and the hex string of the hash of the txHashes
     * @param _proposalId Id of the proposal that proposes to execute the transactions represented by the txHashes
     * @param _txHashes EIP-712 Hashes of the transactions that should be executed
     */
    function buildQuestion(
        string memory _proposalId,
        bytes32[] memory _txHashes
    ) public pure returns (string memory) {
        string memory _txsHash = _bytes32ToAsciiString(
            keccak256(abi.encodePacked(_txHashes))
        );
        return
            string(abi.encodePacked(_proposalId, bytes3(0xe2909f), _txsHash));
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @notice The txIndex used by this function is always 0
     */
    function executeProposal(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) public {
        executeProposalWithIndex(
            _proposalId,
            _txHashes,
            _to,
            _value,
            _data,
            _operation,
            0
        );
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @param _txIndex Index of the transaction hash in txHashes. This is used as the nonce for the transaction, to make the tx hash unique
     */
    function executeProposalWithIndex(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _txIndex
    ) public {
        // We use the hash of the question to check the execution state, as the other parameters might change, but the question not
        bytes32 _questionHash = keccak256(
            bytes(buildQuestion(_proposalId, _txHashes))
        );
        // Lookup question id for this proposal
        bytes32 _questionId = questionIds[_questionHash];

        // Question hash needs to set to be eligible for execution
        require(
            _questionId != bytes32(0),
            "No question id set for provided proposal"
        );
        require(_questionId != INVALIDATED, "Proposal has been invalidated");

        bytes32 _txHash = getTransactionHash(
            _to,
            _value,
            _data,
            _operation,
            _txIndex
        );

        require(_txHashes[_txIndex] == _txHash, "Unexpected transaction hash");

        (
            bool _ifRetrieve,
            bytes memory _valueRetrieved,
            uint256 _timestampReceived
        ) = getDataBefore(_questionId, block.timestamp);

        require(_ifRetrieve, "Data not retrieved");

        // The answer is valid in the time after the cooldown and before the expiration time (if set).
        require(
            _timestampReceived + uint256(questionCooldown) < block.timestamp,
            "Wait for additional cooldown"
        );

        bool _didPass = abi.decode(_valueRetrieved, (bool));

        require(_didPass, "Transaction was not approved");

        uint32 _expiration = answerExpiration;
        require(
            _expiration == 0 ||
                _timestampReceived + uint256(_expiration) >= block.timestamp,
            "Answer has expired"
        );

        // Check this is either the first transaction in the list or that the previous question was already approved
        require(
            _txIndex == 0 ||
                executedProposalTransactions[_questionHash][
                    _txHashes[_txIndex - 1]
                ],
            "Previous transaction not executed yet"
        );
        // Check that this question was not executed yet
        require(
            !executedProposalTransactions[_questionHash][_txHash],
            "Cannot execute transaction again"
        );
        // Mark transaction as executed
        executedProposalTransactions[_questionHash][_txHash] = true;
        // Execute the transaction via the target.

        require(
            exec(_to, _value, _data, _operation),
            "Module transaction failed"
        );
    }

    /**
     * @dev Generate the question id.
     * @notice It is required that this is the same as for the oracle implementation used.
     */
    function getQuestionId(string memory _proposalId)
        public
        pure
        returns (bytes32)
    {
        bytes32 _questionId = keccak256(
            abi.encode("Snapshot", abi.encode(_proposalId))
        );
        return _questionId;
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 _id;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _id := chainid()
        }
        return _id;
    }

    /// @dev Generates the data for the module transaction hash (required for signing)
    function generateTransactionHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes memory) {
        uint256 _chainId = getChainId();
        bytes32 _domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, _chainId, this)
        );
        bytes32 _transactionHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _to,
                _value,
                keccak256(_data),
                _operation,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                _domainSeparator,
                _transactionHash
            );
    }

    function getTransactionHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                generateTransactionHashData(
                    _to,
                    _value,
                    _data,
                    _operation,
                    _nonce
                )
            );
    }

    /**
     * @dev Marks a proposal as invalid, preventing execution of the connected transactions
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @notice This can only be called by the owner
     */
    function markProposalAsInvalid(
        string memory _proposalId,
        bytes32[] memory _txHashes // owner only is checked in markProposalAsInvalidByHash(bytes32)
    ) public {
        string memory _question = buildQuestion(_proposalId, _txHashes);
        bytes32 _questionHash = keccak256(bytes(_question));
        markProposalAsInvalidByHash(_questionHash);
    }

    /**
     * @dev @dev Marks a question hash as invalid, preventing execution of the connected transactions
     * @param _questionHash Question hash calculated based on the proposal id and txHashes
     * @notice This can only be called by the owner
     */
    function markProposalAsInvalidByHash(bytes32 _questionHash)
        public
        onlyOwner
    {
        questionIds[_questionHash] = INVALIDATED;
    }

    /**
     * @dev Marks a proposal with an expired answer as invalid, preventing execution of the connected transactions
     * @param _questionHash Question hash calculated based on the proposal id and txHashes
     */
    function markProposalWithExpiredAnswerAsInvalid(bytes32 _questionHash)
        public
    {
        uint32 _expirationDuration = answerExpiration;
        require(_expirationDuration > 0, "Answers are valid forever");
        bytes32 _questionId = questionIds[_questionHash];
        require(_questionId != INVALIDATED, "Proposal is already invalidated");
        require(
            _questionId != bytes32(0),
            "No question id set for provided proposal"
        );
        (
            bool _ifRetrieve,
            bytes memory _valueRetrieved,
            uint256 _timestampRetrieved
        ) = getDataBefore(_questionId, block.timestamp);

        require(_ifRetrieve, "Data not retrieved");

        bool _didPass = abi.decode(_valueRetrieved, (bool));

        require(_didPass, "Transaction was not approved");

        require(
            _timestampRetrieved + uint256(_expirationDuration) <
                block.timestamp,
            "Answer has not expired yet"
        );

        questionIds[_questionHash] = INVALIDATED;
    }

    /**
     * @dev Sets the duration for which a positive answer is valid.
     * @param _expiration Duration that a positive answer of the oracle is valid in seconds (or 0 if valid forever)
     * @notice A proposal with an expired answer is the same as a proposal that has been marked invalid
     * @notice There need to be at least 60 seconds between end of cooldown and expiration
     * @notice This can only be called by the owner
     */
    function setAnswerExpiration(uint32 _expiration) public onlyOwner {
        require(
            _expiration == 0 || _expiration - questionCooldown >= 60,
            "There need to be at least 60s between end of cooldown and expiration"
        );
        answerExpiration = _expiration;
    }

    function setUp(bytes memory initParams) public override {
        (
            address _owner,
            address _avatar,
            address _target,
            uint32 _cooldown,
            uint32 _expiration
        ) = abi.decode(initParams, (address, address, address, uint32, uint32));
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        require(
            _expiration == 0 || _expiration - _cooldown >= 60,
            "There need to be at least 60s between end of cooldown and expiration"
        );
        avatar = _avatar;
        target = _target;
        answerExpiration = _expiration;
        questionCooldown = _cooldown;

        transferOwnership(_owner);

        emit TellorModuleSetup(msg.sender, _owner, _avatar, _target);
    }

    /**
     * @dev Function to add a proposal that should be considered for execution
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _nonce Nonce that should be used when asking the question on the oracle
     */
    function _addProposalWithNonce(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        uint256 _nonce
    ) internal {
        // We generate the question string used for the oracle
        string memory _question = buildQuestion(_proposalId, _txHashes);
        bytes32 _questionHash = keccak256(bytes(_question));
        if (_nonce > 0) {
            // Previous nonce must have been invalidated by the oracle.
            // However, if the proposal was internally invalidated, it should not be possible to ask it again.
            bytes32 _currentQuestionId = questionIds[_questionHash];
            (bool _ifRetrieve, , ) = getDataBefore(
                _currentQuestionId,
                block.timestamp - questionCooldown
            );
            require(
                _currentQuestionId != INVALIDATED,
                "This proposal has been marked as invalid"
            );
            require(_ifRetrieve, "Data not retrieved");
        } else {
            require(
                questionIds[_questionHash] == bytes32(0),
                "Proposal has already been submitted"
            );
        }
        bytes32 _questionId = getQuestionId(_proposalId);
        // Set the question hash for this question id
        questionIds[_questionHash] = _questionId;
        emit ProposalQuestionCreated(_questionId, _proposalId);
    }

    function _bytes32ToAsciiString(bytes32 _bytes)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(_bytes << (i * 8)));
            uint8 hi = uint8(b) / 16;
            uint8 lo = uint8(b) % 16;
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(uint8 _b) internal pure returns (bytes1 c) {
        if (_b < 10) return bytes1(_b + 0x30);
        else return bytes1(_b + 0x57);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                address(0)
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
           uint256 _count;
        //rinkeby or ethereum check
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            _count = tellor.getTimestampCountById(_queryId);
        } else {
            _count = tellor.getNewValueCountbyQueryId(_queryId);
        }
        if (_count == 0) {
          return (false, bytes(""), 0);
        }
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(
            _queryId,
            _count - 1
        );
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
            uint256 _count;
        //rinkeby or ethereum check
        if (
            tellor == ITellor(0x18431fd88adF138e8b979A7246eb58EA7126ea16) ||
            tellor == ITellor(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)
        ) {
            _count = tellor.getTimestampCountById(_queryId);
        } else {
            _count = tellor.getNewValueCountbyQueryId(_queryId);
        }
        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = tellor.getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get imeadiate next value
                    uint256 _nextTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't found a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        ITellor _governance = ITellor(
            tellor.addresses(
                keccak256(abi.encodePacked("_GOVERNANCE_CONTRACT"))
            )
        );
        return
            _governance
                .getVoteRounds(
                keccak256(abi.encodePacked(_queryId, _timestamp))
            )
                .length >
            0;
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    event ChangedGuard(address guard);

    address public guard;

    /// @dev Set a guard that checks transactions before execution
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            require(
                BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId),
                "Guard does not implement IERC165"
            );
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor{
    //Controller
    function addresses(bytes32) external view returns(address);
    function uints(bytes32) external view returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getAllDisputeVars(uint256 _disputeId) external view returns (bytes32,bool,bool,bool,address,address,address,uint256[9] memory,int256);
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns(uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function isMigrated(address _addy) external view returns (bool);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function isApprovedGovernanceContract(address _contract) external returns (bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteCount() external view returns(uint256);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(bytes32 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReportingLock() external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _maxAmount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256,uint256,bool);
    function getTreasuryCount() external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;
    function migrateFor(address _destination,uint256 _amount) external;
    function rescue51PercentAttack(address _tokenHolder) external;
    function rescueBrokenDataReporting() external;
    function rescueFailedUpdate() external;
}