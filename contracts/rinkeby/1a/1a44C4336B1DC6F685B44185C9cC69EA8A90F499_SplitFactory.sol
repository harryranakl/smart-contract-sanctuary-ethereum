// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitProxy} from "./SplitProxy.sol";

/**
 * @title SplitFactory
 * @author MirrorXYZ
 *
 * @notice Modified to store Minter address
 */
contract SplitFactory {
    //======== Immutable storage =========

    address public immutable splitter;
    address public immutable minter;
    address public immutable wethAddress;

    //======== Mutable storage =========

    // Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Constructor =========

    constructor(
        address splitter_,
        address minter_,
        address wethAddress_
    ) {
        splitter = splitter_;
        minter = minter_;
        wethAddress = wethAddress_;
    }

    //======== Deploy function =========

    function createSplit(bytes32 merkleRoot_)
        external
        returns (address splitProxy)
    {
        merkleRoot = merkleRoot_;
        splitProxy = address(
            new SplitProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitStorage} from "./SplitStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ISplitFactory {
    function splitter() external returns (address);

    function minter() external returns (address);

    function wethAddress() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 *
 * @notice Modified. Use at your own risk.
 * @notice added OpenZeppelin's Ownable (modified) & IERC721Receiver (inherited)
 */
contract SplitProxy is SplitStorage, IERC721Receiver {
    // OpenZeppelin Ownable.sol
    address private _owner;

    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        _minter = ISplitFactory(msg.sender).minter();
        wethAddress = ISplitFactory(msg.sender).wethAddress();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();

        /**
         * @notice Modification of OpenZeppelin Ownable.sol
         * @dev Using tx.origin instead of splitFactory to set owner saves ~25,000 gas over saving to SplitFactory
         * @dev Should be safe in this context... (only used once in the constructor)
         * @dev If that's not the case, please contact: [email protected]
         */
        _setOwner(tx.origin);

        address(_minter).call(
            abi.encodeWithSignature("setApprovalsForSplit(address)", owner())
        );
    }

    /**
     * @notice OpenZeppelin IERC721Receiver.sol
     * @dev Allows contract to receive ERC-721s
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {
        if (msg.sender == owner()) {
            address _impl = minter();
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize())
                let result := call(
                    gas(),
                    _impl,
                    callvalue(),
                    ptr,
                    calldatasize(),
                    0,
                    0
                )
                let size := returndatasize()
                returndatacopy(ptr, 0, size)

                switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
            }
        } else {
            address _impl = splitter();
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize())
                let result := delegatecall(
                    gas(),
                    _impl,
                    ptr,
                    calldatasize(),
                    0,
                    0
                )
                let size := returndatasize()
                returndatacopy(ptr, 0, size)

                switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
            }
        }
    }

    //======== OpenZeppelin Ownable.sol =========
    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev Updates approvals, see Minter.sol
     */
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner());
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        address(_minter).call(
            abi.encodeWithSignature(
                "updateApprovalsForSplit(address,address)",
                _owner,
                newOwner
            )
        );

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    //======== /Ownable.sol =========

    function splitter() public view returns (address) {
        return _splitter;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    // Plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 *
 * Modified to store:
 * address of the deployed Minter Contract
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal wethAddress;
    address internal _splitter;
    address internal _minter;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

// SPDX-License-Identifier: MIT

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

