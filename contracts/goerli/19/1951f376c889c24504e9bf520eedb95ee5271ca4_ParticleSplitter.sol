/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: contracts/interfaces/IParticleSplitter.sol


// IParticleSplitter.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @notice Interface for Particle Splitter
 */
interface IParticleSplitter {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    function executeForWallet(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address externalAddress,
        bytes memory encodedParams
    ) external payable returns (bytes memory);

    function executeForBasket(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address externalAddress,
        bytes memory encodedParams
    ) external payable returns (bytes memory);

    function withdrawWalletRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amountWithdrawn);

    function withdrawBasketRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amountWithdrawn);

    function refreshWalletPrincipal(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event ChargedManagersSet(address indexed chargedManagers);
    event TokenInfoProxySet(address indexed tokenInfoProxy);

    event ExecuteForWallet(
        address indexed contractAddress,
        uint256 tokenId,
        string walletManagerId,
        address indexed externalAddress,
        bytes encodedParams,
        uint256 ethValue
    );
    event ExecuteForBasket(
        address indexed contractAddress,
        uint256 tokenId,
        string basketManagerId,
        address indexed externalAddress,
        bytes encodedParams,
        uint256 ethValue
    );
    event PrincipalRefreshed(
        address contractAddress,
        uint256 tokenId,
        string walletManagerId,
        address assetToken
    );
    event PermsSetForExternal(address indexed contractAddress, bool state);
}

// File: contracts/interfaces/IWalletManager.sol


// IWalletManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @title Particle Wallet Manager interface
 * @dev The wallet-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Wallets
 */
interface IWalletManager {
    event ControllerSet(address indexed controller);
    event ExecutorSet(address indexed executor);
    event PausedStateSet(bool isPaused);
    event NewSmartWallet(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed smartWallet,
        address creator,
        uint256 annuityPct
    );
    event WalletEnergized(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        uint256 assetAmount,
        uint256 yieldTokensAmount
    );
    event WalletDischarged(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        uint256 creatorAmount,
        uint256 receiverAmount
    );
    event WalletDischargedForCreator(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        address creator,
        uint256 receiverAmount
    );
    event WalletReleased(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address assetToken,
        uint256 principalAmount,
        uint256 creatorAmount,
        uint256 receiverAmount
    );
    event WalletRewarded(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address rewardsToken,
        uint256 rewardsAmount
    );

    function isPaused() external view returns (bool);

    function isReserveActive(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external view returns (bool);

    function getReserveInterestToken(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external view returns (address);

    function getTotal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256);

    function getPrincipal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256);

    function getInterest(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256 creatorInterest, uint256 ownerInterest);

    function getRewards(
        address contractAddress,
        uint256 tokenId,
        address rewardToken
    ) external returns (uint256);

    function energize(
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 yieldTokensAmount);

    function discharge(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        address creatorRedirect
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount,
        address creatorRedirect
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeAmountForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address creator,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 receiverAmount);

    function release(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        address creatorRedirect
    )
        external
        returns (
            uint256 principalAmount,
            uint256 creatorAmount,
            uint256 receiverAmount
        );

    function releaseAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount,
        address creatorRedirect
    )
        external
        returns (
            uint256 principalAmount,
            uint256 creatorAmount,
            uint256 receiverAmount
        );

    function withdrawRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amount);

    function executeForAccount(
        address contractAddress,
        uint256 tokenId,
        address externalAddress,
        uint256 ethValue,
        bytes memory encodedParams
    ) external returns (bytes memory);

    function refreshPrincipal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external;

    function getWalletAddressById(
        address contractAddress,
        uint256 tokenId,
        address creator,
        uint256 annuityPct
    ) external returns (address);

    function withdrawEther(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        uint256 amount
    ) external;

    function withdrawERC20(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external;

    function withdrawERC721(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external;
}

// File: contracts/interfaces/IBasketManager.sol


// IBasketManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @title Particle Basket Manager interface
 * @dev The basket-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Baskets
 */
interface IBasketManager {
    event ControllerSet(address indexed controller);
    event ExecutorSet(address indexed executor);
    event PausedStateSet(bool isPaused);
    event NewSmartBasket(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed smartBasket
    );
    event BasketAdd(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address basketTokenAddress,
        uint256 basketTokenId,
        uint256 basketTokenAmount
    );
    event BasketRemove(
        address indexed receiver,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address basketTokenAddress,
        uint256 basketTokenId,
        uint256 basketTokenAmount
    );
    event BasketRewarded(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address rewardsToken,
        uint256 rewardsAmount
    );

    function isPaused() external view returns (bool);

    function getTokenTotalCount(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint256);

    function getTokenCountByType(
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (uint256);

    function prepareTransferAmount(uint256 nftTokenAmount) external;

    function addToBasket(
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (bool);

    function removeFromBasket(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (bool);

    function withdrawRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amount);

    function executeForAccount(
        address contractAddress,
        uint256 tokenId,
        address externalAddress,
        uint256 ethValue,
        bytes memory encodedParams
    ) external returns (bytes memory);

    function getBasketAddressById(address contractAddress, uint256 tokenId)
        external
        returns (address);

    function withdrawEther(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        uint256 amount
    ) external;

    function withdrawERC20(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external;

    function withdrawERC721(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external;

    function withdrawERC1155(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 amount
    ) external;
}

// File: contracts/interfaces/IChargedManagers.sol


// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;


/**
 * @notice Interface for Charged Wallet-Managers
 */
interface IChargedManagers {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    function isContractOwner(address contractAddress, address account)
        external
        view
        returns (bool);

    // ERC20
    function isWalletManagerEnabled(string calldata walletManagerId)
        external
        view
        returns (bool);

    function getWalletManager(string calldata walletManagerId)
        external
        view
        returns (IWalletManager);

    // ERC721
    function isNftBasketEnabled(string calldata basketId)
        external
        view
        returns (bool);

    function getBasketManager(string calldata basketId)
        external
        view
        returns (IBasketManager);

    // Validation
    function validateDeposit(
        address sender,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external;

    function validateNftDeposit(
        address sender,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external;

    function validateDischarge(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    function validateRelease(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    function validateBreakBond(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event WalletManagerRegistered(
        string indexed walletManagerId,
        address indexed walletManager
    );
    event BasketManagerRegistered(
        string indexed basketId,
        address indexed basketManager
    );
}

// File: contracts/interfaces/ITokenInfoProxy.sol


// TokenInfoProxy.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

interface ITokenInfoProxy {
    event ContractFunctionSignatureSet(
        address indexed contractAddress,
        string fnName,
        bytes4 fnSig
    );

    struct FnSignatures {
        bytes4 ownerOf;
        bytes4 creatorOf;
    }

    function setContractFnOwnerOf(address contractAddress, bytes4 fnSig)
        external;

    function setContractFnCreatorOf(address contractAddress, bytes4 fnSig)
        external;

    function getTokenUUID(address contractAddress, uint256 tokenId)
        external
        pure
        returns (uint256);

    function isNFTOwnerOrOperator(
        address contractAddress,
        uint256 tokenId,
        address sender
    ) external returns (bool);

    function isNFTContractOrCreator(
        address contractAddress,
        uint256 tokenId,
        address sender
    ) external returns (bool);

    function getTokenOwner(address contractAddress, uint256 tokenId)
        external
        returns (address);

    function getTokenCreator(address contractAddress, uint256 tokenId)
        external
        returns (address);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts/lib/BlackholePrevention.sol


// BlackholePrevention.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;





/**
 * @notice Prevents ETH or Tokens from getting stuck in a contract by allowing
 *  the Owner/DAO to pull them out on behalf of a user
 * This is only meant to contracts that are not expected to hold tokens, but do handle transferring them.
 */
contract BlackholePrevention {
    using Address for address payable;
    using SafeERC20 for IERC20;

    event WithdrawStuckEther(address indexed receiver, uint256 amount);
    event WithdrawStuckERC20(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );
    event WithdrawStuckERC721(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event WithdrawStuckERC1155(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    function _withdrawEther(address payable receiver, uint256 amount)
        internal
        virtual
    {
        require(receiver != address(0x0), "BHP:E-403");
        if (address(this).balance >= amount) {
            receiver.sendValue(amount);
            emit WithdrawStuckEther(receiver, amount);
        }
    }

    function _withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC20(tokenAddress).balanceOf(address(this)) >= amount) {
            IERC20(tokenAddress).safeTransfer(receiver, amount);
            emit WithdrawStuckERC20(receiver, tokenAddress, amount);
        }
    }

    function _withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC721(tokenAddress).ownerOf(tokenId) == address(this)) {
            IERC721(tokenAddress).transferFrom(
                address(this),
                receiver,
                tokenId
            );
            emit WithdrawStuckERC721(receiver, tokenAddress, tokenId);
        }
    }

    function _withdrawERC1155(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (
            IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount
        ) {
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                receiver,
                tokenId,
                amount,
                ""
            );
            emit WithdrawStuckERC1155(receiver, tokenAddress, tokenId, amount);
        }
    }
}

// File: contracts/ParticleSplitter.sol


// ParticleSplitter.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;









/**
 * @notice Charged Particles Contract
 * @dev Upgradeable Contract
 */
contract ParticleSplitter is
    IParticleSplitter,
    Ownable,
    ReentrancyGuard,
    BlackholePrevention
{
    using Address for address payable;
    IChargedManagers internal _chargedManagers;
    ITokenInfoProxy internal _tokenInfoProxy;

    mapping(address => bool) internal _externalAddressesAllowed;

    /***********************************|
  |        Execute for Account        |
  |__________________________________*/

    /// @notice Executes an arbitrary command on an NFT Wallet
    /// @param contractAddress      The Address to the Contract of the Token
    /// @param tokenId              The ID of the Token
    /// @param walletManagerId      The Wallet Manager controlling the NFT Wallet to execute on
    /// @param externalAddress      The Address of the External Contract to execute on
    /// @param encodedParams        The encoded function call to execute
    function executeForWallet(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address externalAddress,
        bytes memory encodedParams
    )
        external
        payable
        virtual
        override
        onlyTokenOwner(contractAddress, tokenId)
        nonReentrant
        returns (bytes memory)
    {
        require(
            _chargedManagers.isWalletManagerEnabled(walletManagerId),
            "PS:E-419"
        );
        require(_externalAddressesAllowed[externalAddress], "PS:E-117");

        // Validate Owner/Operator & Timelocks
        _chargedManagers.validateRelease(msg.sender, contractAddress, tokenId);

        // Get appropriate Wallet Manager
        IWalletManager walletMgr = _chargedManagers.getWalletManager(
            walletManagerId
        );

        // Get Address of Wallet to send any ETH into
        if (msg.value > 0) {
            address wallet = walletMgr.getWalletAddressById(
                contractAddress,
                tokenId,
                address(0),
                0
            );
            payable(wallet).sendValue(msg.value);
        }

        emit ExecuteForWallet(
            contractAddress,
            tokenId,
            walletManagerId,
            externalAddress,
            encodedParams,
            msg.value
        );

        // Execute command for NFT Wallet
        return
            walletMgr.executeForAccount(
                contractAddress,
                tokenId,
                externalAddress,
                msg.value,
                encodedParams
            );
    }

    /// @notice Executes an arbitrary command on an NFT Basket
    /// @param contractAddress      The Address to the Contract of the Token
    /// @param tokenId              The ID of the Token
    /// @param basketManagerId      The Basket Manager controlling the NFT Wallet to execute on
    /// @param externalAddress      The Address of the External Contract to execute on
    /// @param encodedParams        The encoded function call to execute
    function executeForBasket(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address externalAddress,
        bytes memory encodedParams
    )
        external
        payable
        virtual
        override
        onlyTokenOwner(contractAddress, tokenId)
        nonReentrant
        returns (bytes memory)
    {
        require(
            _chargedManagers.isNftBasketEnabled(basketManagerId),
            "PS:E-419"
        );
        require(_externalAddressesAllowed[externalAddress], "PS:E-117");

        // Validate Owner/Operator & Timelocks
        _chargedManagers.validateRelease(msg.sender, contractAddress, tokenId);

        // Get appropriate Basket Manager
        IBasketManager basketMgr = _chargedManagers.getBasketManager(
            basketManagerId
        );

        // Get Address of Wallet to send any ETH into
        if (msg.value > 0) {
            address wallet = basketMgr.getBasketAddressById(
                contractAddress,
                tokenId
            );
            payable(wallet).sendValue(msg.value);
        }

        emit ExecuteForBasket(
            contractAddress,
            tokenId,
            basketManagerId,
            externalAddress,
            encodedParams,
            msg.value
        );

        // Execute command for NFT Wallet
        return
            basketMgr.executeForAccount(
                contractAddress,
                tokenId,
                externalAddress,
                msg.value,
                encodedParams
            );
    }

    function withdrawWalletRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address rewardsToken,
        uint256 rewardsAmount
    )
        external
        virtual
        override
        onlyTokenOwner(contractAddress, tokenId)
        nonReentrant
        returns (uint256 amountWithdrawn)
    {
        require(
            _chargedManagers.isWalletManagerEnabled(walletManagerId),
            "PS:E-419"
        );

        // Validate Owner/Operator & Timelocks
        _chargedManagers.validateRelease(msg.sender, contractAddress, tokenId);

        // Get appropriate Wallet Manager
        IWalletManager walletMgr = _chargedManagers.getWalletManager(
            walletManagerId
        );

        // Withdraw Rewards for NFT Wallet
        return
            walletMgr.withdrawRewards(
                receiver,
                contractAddress,
                tokenId,
                rewardsToken,
                rewardsAmount
            );
    }

    function withdrawBasketRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address rewardsToken,
        uint256 rewardsAmount
    )
        external
        virtual
        override
        onlyTokenOwner(contractAddress, tokenId)
        nonReentrant
        returns (uint256 amountWithdrawn)
    {
        require(
            _chargedManagers.isNftBasketEnabled(basketManagerId),
            "PS:E-419"
        );

        // Validate Owner/Operator & Timelocks
        _chargedManagers.validateRelease(msg.sender, contractAddress, tokenId);

        // Get appropriate Basket Manager
        IBasketManager basketMgr = _chargedManagers.getBasketManager(
            basketManagerId
        );

        // Withdraw Rewards for NFT Basket
        return
            basketMgr.withdrawRewards(
                receiver,
                contractAddress,
                tokenId,
                rewardsToken,
                rewardsAmount
            );
    }

    function refreshWalletPrincipal(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external virtual override {
        require(
            _chargedManagers.isWalletManagerEnabled(walletManagerId),
            "PS:E-419"
        );

        IWalletManager walletMgr = _chargedManagers.getWalletManager(
            walletManagerId
        );
        walletMgr.refreshPrincipal(contractAddress, tokenId, assetToken);

        emit PrincipalRefreshed(
            contractAddress,
            tokenId,
            walletManagerId,
            assetToken
        );
    }

    /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

    /**
     * @dev Setup the ChargedManagers Interface
     */
    function setChargedManagers(address chargedManagers)
        external
        virtual
        onlyOwner
    {
        _chargedManagers = IChargedManagers(chargedManagers);
        emit ChargedManagersSet(chargedManagers);
    }

    /**
     * @dev Setup the ChargedManagers Interface
     */
    function setTokenInfoProxy(address tokenInfoProxy)
        external
        virtual
        onlyOwner
    {
        _tokenInfoProxy = ITokenInfoProxy(tokenInfoProxy);
        emit TokenInfoProxySet(tokenInfoProxy);
    }

    /**
     * @dev Allows/Disallows execute from on specific contracts
     */
    function setExternalContracts(address[] calldata contracts, bool state)
        external
        onlyOwner
    {
        uint256 count = contracts.length;
        for (uint256 i; i < count; i++) {
            address externalContract = contracts[i];
            _externalAddressesAllowed[externalContract] = state;
            emit PermsSetForExternal(externalContract, state);
        }
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawErc20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }

    function withdrawERC1155(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
    }

    /***********************************|
  |             Modifiers             |
  |__________________________________*/

    modifier onlyTokenOwner(address contractAddress, uint256 tokenId) {
        address tokenOwner = _tokenInfoProxy.getTokenOwner(
            contractAddress,
            tokenId
        );
        require(msg.sender == tokenOwner, "PS:E-102");
        _;
    }
}