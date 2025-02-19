// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "contracts/interfaces/IReentalToken.sol";
import "contracts/interfaces/IReentalManager.sol";
import "contracts/interfaces/IReentalDividends.sol";
import "contracts/interfaces/IWETH.sol";
import "contracts/utils/UUPSUpgradeableByRole.sol";
import "contracts/utils/RefundableUpgradeable.sol";
import "contracts/interfaces/IUniswapV2Router01.sol";

contract ReentalCrowdsale is UUPSUpgradeableByRole, RefundableUpgradeable {

  uint256 public minimum;

  mapping(address => bool) public listed;
  mapping(address => uint256) public poolPercent;
  mapping(address => uint256) public price;
  mapping(address => uint256) public sold;

  event ListedToken(address indexed token, uint256 price, uint256 poolPercent, uint256 listingTime);
  event Contribution(address indexed token, address indexed entryToken, address indexed account, uint256 tokens, uint256 payback, bool reinvest);
  event FullySold(address indexed token);
  event PoolPercentUpdated(address indexed token, uint256 poolPercent);
  event UnlistedToken(address indexed token);

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private immutable _CROWDSALE_ADMIN_ROLE = keccak256("CROWDSALE_ADMIN_ROLE");

  mapping(address => uint256) public listingTime;

  function initialize () public initializer {
    __AccessControlProxyPausable_init(msg.sender);
    minimum = 1 ether; // 1 token
  }

  function setMinimum(
    uint256 min
  ) public onlyRole(_CROWDSALE_ADMIN_ROLE) {
    minimum = min;
  }

  function available(
    address token
  ) public view returns (bool) {
    return listed[token] && block.timestamp > listingTime[token];
  }

  modifier checkPath(
    address[] calldata path
  ) {
    require(path[path.length - 1] == IReentalManager(config).get(keccak256("USDT")), "ReentalCrowdsale: USDT must be the end of the path");
    _;
  }

  function _getRate(
    address aggregator
  ) internal view returns(uint256) {
    AggregatorV3Interface aggregatorInterface = AggregatorV3Interface(aggregator);
    (,int256 answer,,,) = aggregatorInterface.latestRoundData();
    uint8 decimals = aggregatorInterface.decimals();
    return uint256(answer) * uint256(10**uint256(18 - decimals));
  }

  // Gets rates EUR/USD, USDT/USD
  function getRates() public view returns(uint256 usdtRate, uint256 eurRate) {
    return (_getRate(IReentalManager(config).get(keccak256("USDT_USD_FEED"))), _getRate(IReentalManager(config).get(keccak256("EUR_USD_FEED"))));
  }

  function _contribution(
    address account,
    address token,
    uint256 amount,
    bool minRequired
  ) internal whenNotPaused returns (uint256) {
    uint256 tokens = getTokensFromAmount(token, amount);
    uint256 left = getTokensLeft(token);
    if (minRequired && left > minimum) {
      require(tokens >= minimum, "ReentalCrowdsale: contribution failed, not enough tokens");
    }
    require(tokens <= left, "ReentalCrowdsale: not enough tokens left");
    sold[token] += tokens;
    IReentalToken(token).mint(account, tokens);
    if (tokens == left) {
      emit FullySold(token);
    }

    return tokens;
  }

  function contributionExactETHForTokens(
    address token,
    uint256 tokensOutMin,
    address[] calldata path,
    uint256 deadline
  ) public payable checkPath(path) {
    address account = _msgSender();
    address router = IReentalManager(config).get(keccak256("ROUTER"));
    address weth = IUniswapV2Router01(router).WETH();
    uint256 amountOutMin = getAmountFromTokens(token, tokensOutMin);

    require(path[0] == weth, "ReentalCrowdsale: WETH must be the beginning of the path");

    uint256[] memory amounts = IUniswapV2Router01(router).swapExactETHForTokens{ value: msg.value }(amountOutMin, path, address(this), deadline);
  
    uint256 tokens = _contribution(account, token, amounts[amounts.length - 1], true);
    emit Contribution(token, weth, account, tokens, 0, false);
  }

  function contributionETHForExactTokens(
    address token,
    uint256 tokensOut,
    address[] calldata path,
    uint256 deadline
  ) public payable checkPath(path) {
    address account = _msgSender();
    address router = IReentalManager(config).get(keccak256("ROUTER"));
    address weth = IUniswapV2Router01(router).WETH();
    uint256 amountOut = getAmountFromTokens(token, tokensOut);

    require(path[0] == weth, "ReentalCrowdsale: WETH must be the beginning of the path");

    uint256[] memory amounts = IUniswapV2Router01(router).swapETHForExactTokens{ value: msg.value }(amountOut, path, address(this), deadline);
    uint256 payback = msg.value - amounts[0];
    if (payback > 0) {
      payable(msg.sender).transfer(payback);
    }
    uint256 tokens = _contribution(account, token, amounts[amounts.length - 1], true);
    emit Contribution(token, weth, account, tokens, payback, false);
  }

  function contributionDividendsByTokensOut(
    address token,
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 tokensOut
  ) public {
    address account = _msgSender();
    address usdt = IReentalManager(config).get(keccak256("USDT"));
    IReentalDividends dividends = IReentalDividends(IReentalManager(config).get(keccak256("REENTAL_DIVIDENDS")));
    uint256 amountIn = getAmountFromTokens(token, tokensOut);

    dividends.reinvest(index, account, amount, merkleProof, address(this), amountIn);

    uint256 tokens = _contribution(account, token, amountIn, false);
    emit Contribution(token, usdt, account, tokens, 0, true);
  }

  function contributionDividendsByAmountIn(
    address token,
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 amountIn
  ) public {
    address account = _msgSender();
    address usdt = IReentalManager(config).get(keccak256("USDT"));
    IReentalDividends dividends = IReentalDividends(IReentalManager(config).get(keccak256("REENTAL_DIVIDENDS")));

    dividends.reinvest(index, account, amount, merkleProof, address(this), amountIn);

    uint256 tokens = _contribution(account, token, amountIn, false);
    emit Contribution(token, usdt, account, tokens, 0, true);
  }

  function _contributionUSDTForExactTokens(
    address token,
    uint256 amountInMax,
    uint256 tokensOut,
    address entryToken
  ) internal {
    IERC20Upgradeable(entryToken).transferFrom(msg.sender, address(this), amountInMax);
    uint256 amountOut = getAmountFromTokens(token, tokensOut);
    require(amountOut <= amountInMax, "ReentalCrowdsale: oracle has changed");
    uint256 tokens = _contribution(msg.sender, token, amountOut, true);
    uint256 payback = amountInMax - amountOut;

    if (payback > 0) {
      IERC20Upgradeable(entryToken).transfer(msg.sender, payback);
    }

    emit Contribution(token, entryToken, msg.sender, tokens, payback, false);
  }

  function _contributionTokensForExactTokens(
    address token,
    uint256 amountInMax,
    uint256 tokensOut,
    address[] calldata path,
    uint256 deadline
  ) internal {
    address router = IReentalManager(config).get(keccak256("ROUTER"));
    IERC20Upgradeable(path[0]).transferFrom(msg.sender, address(this), amountInMax);
    uint256 amountOut = getAmountFromTokens(token, tokensOut);
    IERC20Upgradeable(path[0]).approve(router, amountInMax);
    uint256[] memory amounts = IUniswapV2Router01(router).swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);
    uint256 tokens = _contribution(msg.sender, token, amountOut, true);
    uint256 payback = amountInMax - amounts[0];

    if (payback > 0) {
      IERC20Upgradeable(path[0]).transfer(msg.sender, payback);
    }

    emit Contribution(token, path[0], msg.sender, tokens, payback, false);
  }

  function contributionTokensForExactTokens(
    address token,
    uint256 amountInMax,
    uint256 tokensOut,
    address[] calldata path,
    uint256 deadline
  ) public checkPath(path) {
    if (path[0] == IReentalManager(config).get(keccak256("USDT"))) {
      _contributionUSDTForExactTokens(token, amountInMax, tokensOut, path[0]);
    } else {
      _contributionTokensForExactTokens(token, amountInMax, tokensOut, path, deadline);
    }
  }

  function contributionExactTokensForTokens(
    address token,
    uint256 amountIn,
    uint256 tokensOutMin,
    address[] calldata path,
    uint256 deadline
  ) public checkPath(path) {
    address account = _msgSender();
    address entryToken = path[0];
    address router = IReentalManager(config).get(keccak256("ROUTER"));

    IERC20Upgradeable(entryToken).transferFrom(account, address(this), amountIn);

    if (entryToken == IReentalManager(config).get(keccak256("USDT"))) {
      uint256 tokens = _contribution(account, token, amountIn, true);
      emit Contribution(token, entryToken, account, tokens, 0, false);
    } else {
      IERC20Upgradeable(entryToken).approve(router, amountIn);
      uint256 amountOutMin = getAmountFromTokens(token, tokensOutMin);
      uint256[] memory amounts = IUniswapV2Router01(router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
      uint256 tokens = _contribution(account, token, amounts[amounts.length - 1], true);
      emit Contribution(token, entryToken, account, tokens, 0, false);
    } 
  }

  function getExternalSold(address token) public view returns (uint256) {
    uint256 supply = IReentalToken(token).totalSupply();
    return supply - sold[token];
  }

  function getOnSale(address token) public view returns (uint256) {
    if(listed[token] && available(token)) {
      uint256 cap_ = IReentalToken(token).cap();
      uint256 ex = getExternalSold(token);
      uint256 pooled = getPooled(token);
      return cap_ - (ex > pooled ? ex : pooled);
    } else {
      return 0;
    }
  }

  function getPooled(address token) public view returns (uint256) {
    uint256 cap_ = IReentalToken(token).cap();
    return (cap_ * poolPercent[token]) / 100 ether;
  }

  function getTokensLeft(address token) public view returns(uint256){
    return getOnSale(token) - sold[token];
  }

  function getTokensFromAmount(address token, uint256 amount) public view returns(uint256){
    (uint256 usdtRate, uint256 eurRate) = getRates();
    return (amount * 1 ether * usdtRate / price[token] / eurRate) + 1; // 1 wei tolerance
  }
  
  function getAmountFromTokens(address token, uint256 amount) public view returns(uint256){
    (uint256 usdtRate, uint256 eurRate) = getRates();
    return amount * eurRate * price[token] / usdtRate / 1 ether;
  }

  function getTokensOut(address token, uint256 amountIn, address[] calldata path) public view checkPath(path) returns (uint256) {
    address entryToken = path[0];
    address router = IReentalManager(config).get(keccak256("ROUTER"));
    address usdt = IReentalManager(config).get(keccak256("USDT"));
    
    if (entryToken == usdt) {
      uint256 tokens = getTokensFromAmount(token, amountIn);
      return tokens;
    } else {
      uint256[] memory amounts = IUniswapV2Router01(router).getAmountsOut(amountIn, path);
      uint256 tokens = getTokensFromAmount(token, amounts[amounts.length - 1]);
      return tokens;
    }   
  }

  function getAmountIn(address token, uint256 tokensOut, address[] calldata path) public view checkPath(path) returns (uint256) {
    address entryToken = path[0];
    address router = IReentalManager(config).get(keccak256("ROUTER"));
    address usdt = IReentalManager(config).get(keccak256("USDT"));

    require(tokensOut <= getTokensLeft(token), "ReentalCrowdsale: not enough tokens left");

    if (entryToken == usdt) {
      return getAmountFromTokens(token, tokensOut);
    } else {
      uint256 amountOut = getAmountFromTokens(token, tokensOut);
      uint256[] memory amounts = IUniswapV2Router01(router).getAmountsIn(amountOut, path);
      return amounts[0];
    }    
  }

  function listToken(address token, uint256 price_, uint256 poolPercent_, uint256 listingOn) public onlyRole(_CROWDSALE_ADMIN_ROLE) {
    require(poolPercent_ <= 100 ether, "ReentalCrowdsale: pool percentage must be under 100 ETH");
    require(price_ > 0, "ReentalCrowdsale: price must be over zero");
    require(listingOn > 0, "ReentalCrowdsale: must be a valid timestamp");

    price[token] = price_;
    poolPercent[token] = poolPercent_;
    listingTime[token] = listingOn;
    listed[token] = true;

    emit ListedToken(token, price_, poolPercent_, listingOn);
    emit PoolPercentUpdated(token, poolPercent_);
  }

  function unlistToken(address token) public onlyRole(_CROWDSALE_ADMIN_ROLE) {
    listed[token] = false;
    price[token] = 0;
    poolPercent[token] = 0;
    listingTime[token] = 0;

    emit UnlistedToken(token);
  }

  function updatePoolPercent(address token, uint256 poolPercent_) public onlyRole(_CROWDSALE_ADMIN_ROLE) {
    require(poolPercent_ <= 100 ether, "ReentalCrowdsale: pool percentage must be under 100 ETH");
    require(listed[token], "ReentalCrowdsale: token must be listed");
    poolPercent[token] = poolPercent_;
    emit PoolPercentUpdated(token, poolPercent_);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// Inspired on https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/presets/ERC20PresetMinterPauserUpgradeable.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IReentalToken {
  function initialize(string memory name, string memory symbol, uint256 supply, address config_) external;
  function swap(address from, address to, uint256 amount) external;
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
  function pause() external;
  function unpause() external;
  function totalSupply() external view returns(uint256);
  function balanceOf(address account) external view returns(uint256);
  function cap() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function config() external view returns (address);
  function transfer(address account, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/// @title The interface of ReentalManager
/// @notice Manages smart contracts deployments, ids and protocol roles
interface IReentalManager is IAccessControlUpgradeable {

    /** EVENTS */

    /// @notice Emitted when a new link is set between id and addr
    /// @param id Hashed identifier linked to proxy
    /// @param proxy Proxy contract address
    /// @param implementation Implementation contract address
    /// @param upgrade Flag: true when the proxy implementation is upgraded
    event Deployment(
        bytes32 indexed id,
        address indexed proxy,
        address indexed implementation,
        bool upgrade
    );

    /// @notice Emitted when an identifier is locked forever to an address
    /// @param id Hashed identifier linked to addr
    /// @param addr Address linked to id
    event Locked(
        bytes32 indexed id,
        address indexed addr
    );

    /// @notice Emitted when a new link is set between id and addr
    /// @param id Hashed identifier linked to addr
    /// @param addr Address linked to id
    event NewId(
        bytes32 indexed id,
        address indexed addr
    );

    /// @notice Emitted when verification state is updated
    /// @param addr Address of the verification updated
    /// @param verified New verification state
    /// @param sender Address of the transaction sender
    event SetVerification(
        address indexed addr,
        bool indexed verified,
        address indexed sender
    );

    /** METHODS */

    /// @notice Deploys / upgrades a proxy contract by deploying a new implementation
    /// @param id Hashed identifier linked to the proxy contract
    /// @param bytecode Bytecode for the new implementation
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    /// @return implementation Address of the new implementation
    function deploy(
        bytes32 id,
        bytes memory bytecode,
        bytes memory initializeCalldata
    ) external returns ( address implementation );

    /// @notice Deploys / overwrites a proxy contract with an existing implementation 
    /// @param id Hashed identifier linked to the proxy contract
    /// @param implementation Address of the existing implementation contract
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    function deployProxyWithImplementation(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) external;

    /// @notice Initializes the manager and sets necessary roles
    function initialize() external;

    /// @notice Locks immutably a link between an address and an id
    /// @param id Hashed identifier linked to the proxy contract
    function lock(
        bytes32 id
    ) external;

    /// @notice Returns whether a hashed identifier is locked or not
    /// @param id Hashed identifier linked to the proxy contract
    /// @return isLocked A boolean: true if locked, false if not
    function locked(
        bytes32 id
    ) external returns ( bool isLocked );

    /// @notice Returns the address linked to a hashed identifier
    /// @param id Hashed identifier
    /// @return addr Address linked to id
    function get(
        bytes32 id
    ) external view returns ( address addr );

    /// @notice Returns the hashed identifier linked to an address
    /// @param addr Address
    /// @return id Hashed identifier linked to addr
    function idOf(
        address addr
    ) external view returns ( bytes32 id );

    /// @notice Returns the implementation of the proxy
    /// @param proxy Proxy address
    /// @return implementation Implementation of the proxy
    function implementationByProxy(
        address proxy
    ) external view returns ( address implementation );

    /// @notice Returns whether an address is verified
    /// @param addr Address
    /// @return verified State of verification
    function isVerified(
        address addr
    ) external view returns ( bool verified );

    /// @notice Sets a link between a hashed identifier and an address
    /// @param id Hashed identifier
    /// @param addr Address
    function setId(
        bytes32 id,
        address addr
    ) external;

    /// @notice Sets a new verification state to an address
    /// @param addr Address
    /// @param verified New verification state
    function setVerification(
        address addr,
        bool verified
    ) external;

    /// @notice Upgrades a proxy contract with an existing implementation 
    /// @param id Hashed identifier linked to the proxy contract
    /// @param implementation Address of the existing implementation contract
    /// @param initializeCalldata Calldata for the initialization of the new contract (if necessary)
    function upgrade(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) external;

    /// @notice Returns upgrader role hashed identifier
    /// @return role Hashed string of UPGRADER_ROLE
    function UPGRADER_ROLE() external returns ( bytes32 role );

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IReentalDividends {

  // Initializes the contract
  function initialize(address config_) external;

  // Updates the contract
  function update(address config_) external;

  // Pauses the contract
  function pause() external;

  // Unpauses the contract
  function unpause() external;

  // Adds a token to the dividends contract
  function addToken(address token) external;

  // Removes a token from the dividends contract
  function removeToken(address token) external;

  // Pays dividends to the dividends contract
  function payDividends(address token, uint256 amount, bytes32 merkleRoot, string memory uri) external;

  // Claims dividends (tax retention is executed)
  function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distribution) external;

  // Claims all dividends (tax retention is executed)
  function claimAll(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

  // Reinvests dividends for a new crowdsale
  function reinvest(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, address to, uint256 distribution) external;

  // Gets whether a token is listed or not
  function listed(address token) external view returns(bool);

  // Gets paid dividends for a token
  function paid(address token) external view returns(uint256);

  // Grants pauser role to an account
  function grantPauserRole(address account) external;

  // Grants admin role to an account
  function grantAdminRole(address account) external;

  // Destroys the contract
  function destroy() external;

  // Gets the pool of selected token in the AMM against dividends Token
  function getPool(address token) external view returns(address);

  // Gets amount claimable for an account
  function claimable(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external view returns(uint256);

  // Gets dividends already distributed
  function distributed(address account) external view returns(uint256);
  
  function config() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./AccessControlProxyPausable.sol";

contract UUPSUpgradeableByRole is AccessControlProxyPausable, UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(keccak256("UPGRADER_ROLE")) {}
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./AccessControlProxyPausable.sol";
import "contracts/lib/Msg.sol";

contract RefundableUpgradeable is AccessControlProxyPausable {

  mapping(address=>uint256) public refunded;
  uint256 public refundedETH;

  receive() external payable {}

  fallback() external payable {}

  function __Refundable_init() internal initializer {
    __AccessControlProxyPausable_init(msg.sender);
    __Refundable_init_unchained();
  }

  function __Refundable_init_unchained() internal initializer {
  }

  function refundTokens(address token, address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {

    (bool success1, bytes memory result1) = token.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
    uint256 balance = uint256(Msg.sliceUint(result1, 0));

    require(success1 && balance > 0, "RefundableUpgradeable: cannot transfer funds");

    refunded[token] += balance;

    (bool success2, bytes memory result2) = token.call(abi.encodeWithSignature("transfer(address,uint256)", recipient, balance));
    
    if (!success2) {
      revert(Msg.getRevertMsg(result2));
    }
  }
  
  function refundETH(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;

    require(balance > 0, "RefundableUpgradeable: cannot transfer funds");

    refundedETH += balance;

    payable(recipient).transfer(balance);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is ERC1967Upgrade {
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {

    address public config;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(hasRole(role, account), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                ));
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControlUpgradeable configInterface = IAccessControlUpgradeable(config);
        return configInterface.hasRole(role, account);
    }

    function __AccessControlProxyPausable_init(address config_) internal initializer {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(config_);
    }

    function __AccessControlProxyPausable_init_unchained(address config_) internal initializer {
        config = config_;
    }

    function pause() public onlyRole(PAUSER_ROLE){
        _pause();
    }
    
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function updateConfig(address config_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IAccessControlUpgradeable configInterface = IAccessControlUpgradeable(config_);
        require(configInterface.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
                    )
                ));
        config = config_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
library StorageSlot {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library Msg {

    function sliceUint(bytes memory bs, uint start) internal pure returns (uint)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function getRevertMsg(bytes memory returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}