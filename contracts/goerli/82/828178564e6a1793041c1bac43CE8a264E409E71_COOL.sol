/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT

// Set solidity version
pragma solidity ^0.8.5;

// Import math library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// Set ERC20 basic interface
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Set ownable modifier
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

// Set create pair uniswap interface
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Set swap uniswap interface
interface IDEXRouter {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

////////////////////////////  FUN STARTS  //////////////////////////

contract COOL is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Cool Contract";
    string constant _symbol = "PHO";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals);

    // Set 2% Max Wallet Amount
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) public _buyMap;
    mapping(address => bool) public bots;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 0; 

    uint256 public liquidityFeeBuy = 4;
    uint256 public liquidityFeeSell = 2;
    uint256 public liquidityFeeEarlySell = 40;

    uint256 marketingFee = 8;

    uint256 public marketingFeeBuy = 6;
    uint256 public marketingFeeSell = 50;
    uint256 public marketingFeeEarlySell = 50;

    uint256 totalFee = liquidityFee + marketingFee;

    uint256 feeDenominator = 100;

    address public marketingFeeReceiver = 0x017006342770cDDc9EbCe1568d3ba6B73971BCC4;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 5; // 0.5%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    // This is so the contract can receive eth and tokens
    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    // Blacklist address
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    // Unblacklist address
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    // Main transfer logic
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");

        bool isSell = recipient == pair || recipient == address(router);

        if (isSell) {
            // If sell before 24 hours, fees are higher
            if(_buyMap[sender] != 0 && (_buyMap[sender] + (24 * 1 hours) >= block.timestamp)) {
                liquidityFee = liquidityFeeEarlySell;
                marketingFee = marketingFeeEarlySell;
            } else {
                liquidityFee = liquidityFeeSell;
                marketingFee = marketingFeeSell;
            }
        } else {
            if (_buyMap[recipient] == 0) {
                _buyMap[recipient] = block.timestamp;
            }

            liquidityFee = liquidityFeeBuy;
            marketingFee = marketingFeeBuy;
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); } 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    // Basic transfer
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Check if address is whitelisted
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    // Specific function that takes the fees
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    // Check if it should take fees
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    // Function to get the fees
    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        // The "to" parameter set to owner, this is the address that will receive the liquidity tokens after the transaction is done.
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    // Set regular fees, these don't matter since they will be changed at transfer anyway but wanted to still add it.
    function setRegularFees(uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        require((_marketingFee + _liquidityFee) <= 25, "Must keep fees at 25% or less");
         liquidityFee = _liquidityFee; 
         marketingFee = _marketingFee;
         totalFee = liquidityFee + marketingFee;
    } 

    // Set buy fees
    function setBuyFees(uint256 _marketingFeeBuy, uint256 _liquidityFeeBuy) external onlyOwner {
        require((_marketingFeeBuy + _liquidityFeeBuy) <= 25, "Must keep fees at 25% or less");
        marketingFeeBuy = _marketingFeeBuy;
        liquidityFeeBuy = _liquidityFeeBuy;
    }

    // Set sell fees
    function setSellFees(uint256 _marketingFeeSell, uint256 _liquidityFeeSell) external onlyOwner {
        require((_marketingFeeSell + _liquidityFeeSell) <= 25, "Must keep fees at 25% or less");
        marketingFeeSell = _marketingFeeSell;
        liquidityFeeSell = _liquidityFeeSell;
    }

    // Set early sell fees
    function setEarlySellFees(uint256 _marketingFeeEarlySell, uint256 _liquidityFeeEarlySell) external onlyOwner {
        require((_marketingFeeEarlySell + _liquidityFeeEarlySell) <= 50, "Must keep fees at 80% or less");
        liquidityFeeEarlySell = _liquidityFeeEarlySell;
        marketingFeeEarlySell = _marketingFeeEarlySell;
    }

    // Change the marketing fee receiver 
    function changeMarketingFeeReceiver(address _newMarketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _newMarketingFeeReceiver;
    }

    // Function used for the take fees function
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    //Withdraw all eth in contract
    function clearStuckBalance() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    // Set Max wallet
    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 1000;
    }   

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}