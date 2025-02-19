// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// import "hardhat/console.sol";
import {EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation} from "./CaveatEnforcer.sol";
import {DelegatableCore} from "./DelegatableCore.sol";
import {IDelegatable} from "./interfaces/IDelegatable.sol";

/* @notice AppStorage is used so ERC2535 Diamond facets do not clobber each others' storage.
 * https://eip2535diamonds.substack.com/p/keep-your-data-right-in-eip2535-diamonds?utm_source=substack&utm_campaign=post_embed&utm_medium=web
 */
struct AppStorage {
    bytes32 eip712domainTypeHash;
}

contract DelegatableFacet is IDelegatable, DelegatableCore {
    AppStorage internal s;

    /* ===================================================================================== */
    /* External Functions                                                                    */
    /* ===================================================================================== */

    /**
     * @notice Typehash Initializer - To be called by a diamond after facet assignment.
     * Yes, anyone can assign the facet's own name, but it doesn't do anything, so it's fine.
     */
    function setDomainHash(string calldata contractName) public {
        s.eip712domainTypeHash = getEIP712DomainHash(
            contractName,
            "1",
            block.chainid,
            address(this)
        );
    }

    /**
     * @notice Domain Hash Getter
     * @return bytes32 - The domain hash of the calling contract.
     */
    function getEIP712DomainHash() public view returns (bytes32) {
        bytes32 domainHash = s.eip712domainTypeHash;
        require(domainHash != 0, "Domain hash not set");
        return domainHash;
    }

    /// @inheritdoc IDelegatable
    function getDelegationTypedDataHash(Delegation memory delegation)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getEIP712DomainHash(),
                GET_DELEGATION_PACKETHASH(delegation)
            )
        );
        return digest;
    }

    /// @inheritdoc IDelegatable
    function getInvocationsTypedDataHash(Invocations memory invocations)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getEIP712DomainHash(),
                GET_INVOCATIONS_PACKETHASH(invocations)
            )
        );
        return digest;
    }

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        );
        return keccak256(encoded);
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        override(IDelegatable, DelegatableCore)
        returns (address)
    {
        Delegation memory delegation = signedDelegation.delegation;
        bytes32 sigHash = getDelegationTypedDataHash(delegation);
        address recoveredSignatureSigner = recover(
            sigHash,
            signedDelegation.signature
        );
        return recoveredSignatureSigner;
    }

    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        public
        view
        returns (address)
    {
        bytes32 sigHash = getInvocationsTypedDataHash(
            signedInvocation.invocations
        );
        address recoveredSignatureSigner = recover(
            sigHash,
            signedInvocation.signature
        );
        return recoveredSignatureSigner;
    }

    // --------------------------------------
    // WRITES
    // --------------------------------------

    /// @inheritdoc IDelegatable
    function contractInvoke(Invocation[] calldata batch)
        external
        override
        returns (bool)
    {
        return _invoke(batch, msg.sender);
    }

    /// @inheritdoc IDelegatable
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        override
        returns (bool success)
    {
        for (uint256 i = 0; i < signedInvocations.length; i++) {
            SignedInvocation calldata signedInvocation = signedInvocations[i];
            address invocationSigner = verifyInvocationSignature(
                signedInvocation
            );
            _enforceReplayProtection(
                invocationSigner,
                signedInvocations[i].invocations.replayProtection
            );
            _invoke(signedInvocation.invocations.batch, invocationSigner);
        }
    }

    /*
     * @notice Overrides the msgSender to enable delegation message signing.
     * @returns address - The account whose authority is being acted on.
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore)
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    /* ===================================================================================== */
    /* Internal Functions                                                                    */
    /* ===================================================================================== */
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "./libraries/ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Invocation {
    Transaction transaction;
    SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256(
    "Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Invocations {
    Invocation[] batch;
    ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256(
    "Invocations(Invocation[] batch,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct SignedInvocation {
    Invocations invocations;
    bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256(
    "SignedInvocation(Invocations invocations,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Transaction {
    address to;
    uint256 gasLimit;
    bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 gasLimit,bytes data)"
);

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256(
    "ReplayProtection(uint nonce,uint queue)"
);

struct Delegation {
    address delegate;
    bytes32 authority;
    Caveat[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegate,bytes32 authority,Caveat[] caveats)Caveat(address enforcer,bytes terms)"
);

struct Caveat {
    address enforcer;
    bytes terms;
}

bytes32 constant CAVEAT_TYPEHASH = keccak256(
    "Caveat(address enforcer,bytes terms)"
);

struct SignedDelegation {
    Delegation delegation;
    bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256(
    "SignedDelegation(Delegation delegation,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)"
);

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {
    // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

    // function GET_EIP712DOMAIN_PACKETHASH(EIP712Domain memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         EIP712DOMAIN_TYPEHASH,
    //         _input.name,
    //         _input.version,
    //         _input.chainId,
    //         _input.verifyingContract
    //     );

    //     return keccak256(encoded);
    // }

    function GET_INVOCATION_PACKETHASH(Invocation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATION_TYPEHASH,
            GET_TRANSACTION_PACKETHASH(_input.transaction),
            GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(
        SignedDelegation[] memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_SIGNEDDELEGATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_INVOCATIONS_PACKETHASH(Invocations memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATIONS_TYPEHASH,
            GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
            GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
        );

        return keccak256(encoded);
    }

    function GET_INVOCATION_ARRAY_PACKETHASH(Invocation[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_INVOCATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    // function GET_SIGNEDINVOCATION_PACKETHASH(SignedInvocation memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         SIGNEDINVOCATION_TYPEHASH,
    //         GET_INVOCATIONS_PACKETHASH(_input.invocations),
    //         keccak256(_input.signature)
    //     );

    //     return keccak256(encoded);
    // }

    function GET_TRANSACTION_PACKETHASH(Transaction memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            TRANSACTION_TYPEHASH,
            _input.to,
            _input.gasLimit,
            keccak256(_input.data)
        );

        return keccak256(encoded);
    }

    function GET_REPLAYPROTECTION_PACKETHASH(ReplayProtection memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            REPLAYPROTECTION_TYPEHASH,
            _input.nonce,
            _input.queue
        );

        return keccak256(encoded);
    }

    function GET_DELEGATION_PACKETHASH(Delegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            DELEGATION_TYPEHASH,
            _input.delegate,
            _input.authority,
            GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
        );

        return keccak256(encoded);
    }

    function GET_CAVEAT_ARRAY_PACKETHASH(Caveat[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(encoded, GET_CAVEAT_PACKETHASH(_input[i]));
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_CAVEAT_PACKETHASH(Caveat memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            CAVEAT_TYPEHASH,
            _input.enforcer,
            keccak256(_input.terms)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_PACKETHASH(SignedDelegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            SIGNEDDELEGATION_TYPEHASH,
            GET_DELEGATION_PACKETHASH(_input.delegation),
            keccak256(_input.signature)
        );

        return keccak256(encoded);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./TypesAndDecoders.sol";

abstract contract CaveatEnforcer {
    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata tx,
        bytes32 delegationHash
    ) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EIP712Decoder, EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation, Transaction, ReplayProtection, CaveatEnforcer} from "./CaveatEnforcer.sol";

abstract contract DelegatableCore is EIP712Decoder {
    /// @notice Account delegation nonce manager
    mapping(address => mapping(uint256 => uint256)) internal multiNonce;

    function getNonce(address intendedSender, uint256 queue)
        external
        view
        returns (uint256)
    {
        return multiNonce[intendedSender][queue];
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        returns (address);

    function _enforceReplayProtection(
        address intendedSender,
        ReplayProtection memory protection
    ) internal {
        uint256 queue = protection.queue;
        uint256 nonce = protection.nonce;
        require(
            nonce == (multiNonce[intendedSender][queue] + 1),
            "DelegatableCore:nonce2-out-of-order"
        );
        multiNonce[intendedSender][queue] = nonce;
    }

    function _execute(
        address to,
        bytes memory data,
        uint256 gasLimit,
        address sender
    ) internal returns (bool success) {
        bytes memory full = abi.encodePacked(data, sender);
        assembly {
            success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
        }
    }

    function _invoke(Invocation[] calldata batch, address sender)
        internal
        returns (bool success)
    {
        for (uint256 x = 0; x < batch.length; x++) {
            Invocation memory invocation = batch[x];
            address intendedSender;
            address canGrant;

            // If there are no delegations, this invocation comes from the signer
            if (invocation.authority.length == 0) {
                intendedSender = sender;
                canGrant = intendedSender;
            }

            bytes32 authHash = 0x0;

            for (uint256 d = 0; d < invocation.authority.length; d++) {
                SignedDelegation memory signedDelegation = invocation.authority[
                    d
                ];
                address delegationSigner = verifyDelegationSignature(
                    signedDelegation
                );

                // Implied sending account is the signer of the first delegation
                if (d == 0) {
                    intendedSender = delegationSigner;
                    canGrant = intendedSender;
                }

                require(
                    delegationSigner == canGrant,
                    "DelegatableCore:invalid-delegation-signer"
                );

                Delegation memory delegation = signedDelegation.delegation;
                require(
                    delegation.authority == authHash,
                    "DelegatableCore:invalid-authority-delegation-link"
                );

                // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
                // otherwise once it's revoked, you can't give the exact same permission again.
                bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(
                    signedDelegation
                );

                // Each delegation can include any number of caveats.
                // A caveat is any condition that may reject a proposed transaction.
                // The caveats specify an external contract that is passed the proposed tx,
                // As well as some extra terms that are used to parameterize the enforcer.
                for (uint16 y = 0; y < delegation.caveats.length; y++) {
                    CaveatEnforcer enforcer = CaveatEnforcer(
                        delegation.caveats[y].enforcer
                    );
                    bool caveatSuccess = enforcer.enforceCaveat(
                        delegation.caveats[y].terms,
                        invocation.transaction,
                        delegationHash
                    );
                    require(caveatSuccess, "DelegatableCore:caveat-rejected");
                }

                // Store the hash of this delegation in `authHash`
                // That way the next delegation can be verified against it.
                authHash = delegationHash;
                canGrant = delegation.delegate;
            }

            // Here we perform the requested invocation.
            Transaction memory transaction = invocation.transaction;

            require(
                transaction.to == address(this),
                "DelegatableCore:invalid-invocation-target"
            );

            // TODO(@kames): Can we bubble up the error message from the enforcer? Why not? Optimizations?
            success = _execute(
                transaction.to,
                transaction.data,
                transaction.gasLimit,
                intendedSender
            );
            require(success, "DelegatableCore::execution-failed");
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Allows a smart contract to submit a batch of invocations for processing, allowing itself to be the delegate.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Allows anyone to submit a batch of signed invocations for processing.
     * @param signedInvocations SignedInvocation[] - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        returns (bool success);

    /**
     * @notice Returns the typehash for this contract's delegation signatures.
     * @param delegation Delegation - The delegation to get the type of
     * @return bytes32 - The type of the delegation
     */
    function getDelegationTypedDataHash(Delegation memory delegation)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the typehash for this contract's invocation signatures.
     * @param invocations Invocations
     * @return bytes32 - The type of the Invocations
     */
    function getInvocationsTypedDataHash(Invocations memory invocations)
        external
        view
        returns (bytes32);

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) external pure returns (bytes32);

    /**
     * @notice Verifies that the given invocation is valid.
     * @param signedInvocation - The signed invocation to verify
     * @return address - The address of the account authorizing this invocation to act on its behalf.
     */
    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        external
        view
        returns (address);

    /**
     * @notice Verifies that the given delegation is valid.
     * @param signedDelegation - The delegation to verify
     * @return address - The address of the account authorizing this delegation to act on its behalf.
     */
    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        external
        view
        returns (address);
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

contract ECRecovery {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}