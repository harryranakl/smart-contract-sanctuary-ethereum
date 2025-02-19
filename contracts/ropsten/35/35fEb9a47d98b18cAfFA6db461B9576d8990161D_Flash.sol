// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

contract Flash is Ownable {
    // using SafeMath for uint256;

    constructor() {}

    // function claimTokens(address _token, uint256 _amount) external onlyOwner {
    //     address payable ownerPayable = address(uint160(owner()));
    //     uint256 amount = _amount;
    //     if (_amount == 0) {
    //         amount = address(this).balance;
    //     }
    //     if (_token == address(0)) {
    //         ownerPayable.transfer(amount);
    //         return;
    //     }
    //     ERC20 erc20token = ERC20(_token);
    //     amount = erc20token.balanceOf(address(this));
    //     erc20token.transfer(ownerPayable, amount);
    // }

    // function uniswapV2Call(
    //     address sender,
    //     uint256 amount0,
    //     uint256 amount1,
    //     bytes calldata data
    // ) external override {
    //     IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(router);
    //     address[] memory path = new address[](2);
    //     path[0] = uniswapV2Router.WETH();
    //     path[1] = token;
    //     uint256[] memory amountIn = uniswapV2Router.getAmountsIn(amount, path);
    //     IWETH(path[0]).approve(router, 100000000 * 10**6 * 10**9);
    //     while (IWETH(path[0]).balanceOf(address(this)) > amountIn[0]) {
    //         // make the swap
    //         uniswapV2Router.swapTokensForExactTokens(
    //             amount, // accept any amount of Tokens
    //             amountIn[0] + 1,
    //             path,
    //             address(this), // Burn address
    //             block.timestamp.add(300)
    //         );
    //         amountIn = uniswapV2Router.getAmountsIn(amount, path);
    //     }
    //     uniswapV2Router.swapExactTokensForTokens(
    //         IWETH(path[0]).balanceOf(address(this)), // accept any amount of Tokens
    //         0,
    //         path,
    //         address(this), // Burn address
    //         block.timestamp.add(300)
    //     );

    //     this.sendToken(token, pairAddress);

    //     path[0] = token;
    //     path[1] = uniswapV2Router.WETH();

    //     ERC20(token).approve(router, 100000000 * 10**6 * 10**9);

    //     while (ERC20(token).balanceOf(address(this)) >= amount) {
    //         // make the swap
    //         uniswapV2Router.swapExactTokensForTokens(
    //             amount, // accept any amount of Tokens
    //             0,
    //             path,
    //             address(this),
    //             block.timestamp.add(300)
    //         );
    //     }
    //     uniswapV2Router.swapExactTokensForTokens(
    //         ERC20(token).balanceOf(address(this)), // accept any amount of Tokens
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp.add(300)
    //     );
    //     IWETH(path[0]).transfer(msg.sender, amount1.add((amount1 * 3) / 1000) + 1);
    // }

    uint256 brrow;
    address addressFrom;
    address router;
    address token;
    uint256 amount;
    address pairAddress;

    // function startFlash(
    //     uint256 _brrow,
    //     address _addressFrom,
    //     address _router,
    //     address _token,
    //     uint256 _amount,
    //     address _pairAddress
    // ) external onlyOwner {
    //     brrow = _brrow;
    //     addressFrom = _addressFrom;
    //     router = _router;
    //     token = _token;
    //     amount = _amount;
    //     pairAddress = _pairAddress;
    //     IUniswapV2Pair(addressFrom).swap(0, brrow, address(this), "falsh");
    // }

    function sendToken(
        address _token,
        address to,
        uint256 amount
    ) external {
        IWETH erc20token = IWETH(_token);
        for (uint256 i = 0; i < amount; i++) {
            erc20token.transfer(to, 1);
        }
    }

    function collectEther() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}