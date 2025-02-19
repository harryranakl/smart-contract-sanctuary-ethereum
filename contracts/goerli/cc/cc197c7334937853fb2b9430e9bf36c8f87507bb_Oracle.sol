/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

/*
 * Multi-Token Rate Oracle
 * Oracle for conversion rates of native currency and ERC20 tokens to EUR
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    function setName(string calldata name) external returns (bytes32 node);
}

// File: contracts/OracleRequestI.sol

/*
 * Interface for requests to the rate oracle (for EUR/ETH)
 * Copy this to projects that need to access the oracle.
 * See rate-oracle project for implementation.
 */

interface OracleRequestI {

    /**
     * @dev Number of wei per EUR
     */
    function EUR_WEI() external view returns (uint256);

    /**
     * @dev Timestamp of when the last update occurred
     */
    function lastUpdate() external view returns (uint256);

    /**
     * @dev Number of EUR per ETH (rounded down!)
     */
    function ETH_EUR() external view returns (uint256);

    /**
     * @dev Number of EUR cent per ETH (rounded down!)
     */
    function ETH_EURCENT() external view returns (uint256);

}

// File: contracts/MultiOracleRequestI.sol

/*
 * Interface for requests to the multi-rate oracle (for EUR/ETH and ERC20)
 * Copy this to projects that need to access the oracle.
 * This is a strict superset of OracleRequestI to ensure compatibility.
 * See rate-oracle project for implementation.
 */

interface MultiOracleRequestI {

    /**
     * @dev Number of wei per EUR
     */
    function EUR_WEI() external view returns (uint256);

    /**
     * @dev Timestamp of when the last update for the ETH rate occurred
     */
    function lastUpdate() external view returns (uint256);

    /**
     * @dev Number of EUR per ETH (rounded down!)
     */
    function ETH_EUR() external view returns (uint256);

    /**
     * @dev Number of EUR cent per ETH (rounded down!)
     */
    function ETH_EURCENT() external view returns (uint256);

    /**
     * @dev True for ERC20 tokens that are supported by this oracle, false otherwise
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Number of token units per EUR
     */
    function eurRate(address tokenAddress) external view returns(uint256);

    /**
     * @dev Timestamp of when the last update for the specific ERC20 token rate occurred
     */
    function lastRateUpdate(address tokenAddress) external view returns (uint256);

    /**
     * @dev Emitted on rate update - using address(0) as tokenAddress for ETH updates
     */
    event RateUpdated(address indexed tokenAddress, uint256 indexed eurRate);

}

// File: contracts/Oracle.sol

/*
 * Implements a multi-token rate oracle for conversion rates of native currency
 * and ERC20 tokens to EUR
 */

contract Oracle is MultiOracleRequestI {

    address public rateControl;
    address public tokenAssignmentControl;

    mapping(address => uint256) private eurRateStore;
    mapping(address => uint256) private lastUpdateStore;

    mapping(address => address) public mapToken; // Map a token address to another address, e.g. for wETH
    address public constant mapEthPlaceholder = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    event RateControlTransferred(address indexed previousRateControl, address indexed newRateControl);
    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);
    event TokenMapUpdated(address indexed tokenAddress, address indexed mappedToAddress);
    event TokenMapRemoved(address indexed tokenAddress);


    constructor(address _rateControl, address _tokenAssignmentControl)
    {
        rateControl = _rateControl;
        tokenAssignmentControl = _tokenAssignmentControl;
    }

    modifier onlyRateControl()
    {
        require(msg.sender == rateControl, "rateControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function transferRateControl(address _newRateControl)
    public
    onlyRateControl
    {
        require(_newRateControl != address(0), "rateControl cannot be the zero address.");
        emit RateControlTransferred(rateControl, _newRateControl);
        rateControl = _newRateControl;
    }

    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    /*** Map addresses, e.g. for wETH ***/

    // Add a token mapping (i.e. address of this toke will map to rate of another token).
    function setMappedToken(address _tokenAddress, address _mapToAddress)
    public
    onlyRateControl
    {
        if (_mapToAddress == address(0)) {
          mapToken[_tokenAddress] = mapEthPlaceholder;
        }
        else {
          mapToken[_tokenAddress] = _mapToAddress;
        }
        emit TokenMapUpdated(_tokenAddress, _mapToAddress);
    }

    // Remove token mapping.
    function removeTokenMapping(address _tokenAddress)
    public
    onlyRateControl
    {
        mapToken[_tokenAddress] = address(0);
        emit TokenMapRemoved(_tokenAddress);
    }

    // Map an address - returns the token address to look up the rate for.
    // This is the original address if no mapping exists or the address it maps to.
    function mapAddress(address _tokenAddress)
    public view
    returns(address)
    {
        if (mapToken[_tokenAddress] == mapEthPlaceholder) {
            return address(0);
        }
        if (mapToken[_tokenAddress] != address(0)) {
            return mapToken[_tokenAddress];
        }
        return _tokenAddress;
    }

    /*** Set Rate ***/

    // Set rate of any token (relative to EUR)
    function setTokenRate(address _tokenAddress, uint256 _new_eurRate)
    public
    onlyRateControl
    {
        require(_new_eurRate > 0, "Please assign a valid rate.");
        lastUpdateStore[_tokenAddress] = block.timestamp;
        eurRateStore[_tokenAddress] = _new_eurRate;
        emit RateUpdated(_tokenAddress, _new_eurRate);
    }

    // Specifically set rate of ETH (compat with first version of Oracle)
    function setRate(uint256 _new_EUR_WEI)
    public
    onlyRateControl
    {
        setTokenRate(address(0), _new_EUR_WEI);
    }

    // Disabling a token just sets its rate to 0 (specific function so this cannot happen by accident).
    function disableToken(address _tokenAddress)
    public
    onlyRateControl
    {
        lastUpdateStore[_tokenAddress] = block.timestamp;
        eurRateStore[_tokenAddress] = 0;
        emit RateUpdated(_tokenAddress, 0);
    }

    /*** Return per-token values ***/

    // Rate of the token in EUR. Use the zero address for the ETH rate.
    function eurRate(address _tokenAddress)
    public view
    override
    returns(uint256)
    {
        uint256 rate = eurRateStore[mapAddress(_tokenAddress)];
        require(rate > 0, "Token not supported.");
        return rate;
    }

    // Timestamp (seconds since 1970-01-01 00:00:00 UTC) of last rate update for this token.
    function lastRateUpdate(address _tokenAddress)
    public view
    override
    returns(uint256)
    {
        return lastUpdateStore[mapAddress(_tokenAddress)];
    }

    // Returns true if that token is supported by this oracle, false otherwise.
    function tokenSupported(address _tokenAddress)
    public view
    override
    returns(bool)
    {
        return eurRateStore[mapAddress(_tokenAddress)] > 0;
    }

    /*** Compatibility with non-ERC20-aware OracleRequestI functions ***/

    // Number of wei per EUR
    function EUR_WEI()
    public view
    override
    returns (uint256)
    {
        return eurRateStore[address(0)];
    }

    // Timestamp of when the last update (of ETH rate) occurred
    function lastUpdate()
    public view
    override
    returns (uint256)
    {
        return lastUpdateStore[address(0)];
    }

    // Number of EUR per ETH (rounded down!)
    function ETH_EUR()
    public view override
    returns (uint256)
    {
        return uint256(1 ether) / EUR_WEI();
    }

    // Number of EUR cent per ETH (rounded down!)
    function ETH_EURCENT()
    public view override
    returns (uint256)
    {
        return uint256(100 ether) / EUR_WEI();
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respective network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // For Mainnet, the address needed is 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(address _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}