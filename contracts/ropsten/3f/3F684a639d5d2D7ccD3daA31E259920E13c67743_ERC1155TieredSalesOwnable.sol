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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC1155TieredSalesStorage.sol";
import "./IERC1155TieredSalesAdmin.sol";

/**
 * @title ERC1155 - Tiered Sales - Admin - Ownable
 * @notice Used to manage which ERC1155 token is related to which the sales tier.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies 0x91cb770f
 * @custom:provides-interfaces 0x76c5dd21
 */
contract ERC1155TieredSalesOwnable is IERC1155TieredSalesAdmin, OwnableInternal {
    using ERC1155TieredSalesStorage for ERC1155TieredSalesStorage.Layout;

    function configureTierTokenId(uint256 tierId, uint256 tokenId) external onlyOwner {
        ERC1155TieredSalesStorage.layout().tierToTokenId[tierId] = tokenId;
    }

    function configureTierTokenId(uint256[] calldata tierIds, uint256[] calldata tokenIds) external onlyOwner {
        require(
            tierIds.length == tokenIds.length,
            "ERC1155TieredSalesOwnable: tierIds and tokenIds must be same length"
        );

        for (uint256 i = 0; i < tierIds.length; i++) {
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierIds[i]] = tokenIds[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library ERC1155TieredSalesStorage {
    struct Layout {
        mapping(uint256 => uint256) tierToTokenId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155TieredSales");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC1155TieredSalesAdmin {
    function configureTierTokenId(uint256 tierId, uint256 tokenId) external;

    function configureTierTokenId(uint256[] calldata tierIds, uint256[] calldata tokenIds) external;
}