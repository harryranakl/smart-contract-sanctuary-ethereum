// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IUniRouter02.sol";
import "./interfaces/IWETH.sol";

// SpectreLabzFarm is the master of spectre. He can make brews and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once brews is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SpectreLabzFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 reflectionDebt;     // Reflection debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of brewss
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. brewss to distribute per block.
        uint256 duration;
        uint256 startBlock;
        uint256 bonusEndBlock;
        uint256 lastRewardBlock;  // Last block number that brewss distribution occurs.
        uint256 accTokenPerShare;   // Accumulated brewss per share, times 1e12. See below.
        uint256 accReflectionPerShare;   // Accumulated brewss per share, times 1e12. See below.
        uint256 lastReflectionPerPoint;
        uint16 depositFee;      // Deposit fee in basis points
        uint16 withdrawFee;      // Deposit fee in basis points
    }

    struct SwapSetting {
        IERC20 lpToken;
        address swapRouter;
        address[] earnedToToken0;
        address[] earnedToToken1;
        address[] reflectionToToken0;
        address[] reflectionToToken1;
        bool enabled;
    }

    // The brews TOKEN!
    IERC20 public brews;
    // Reflection Token
    address public reflectionToken;
    uint256 public accReflectionPerPoint;
    bool public hasDividend;

    // brews tokens created per block.
    uint256 public rewardPerBlock;
    // Bonus muliplier for early brews makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    address public buyBackWallet = 0x40Ef716084e6F3D53B1715427880BFD09Fdf9c0C;
    uint256 public performanceFee = 0.00089 ether;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    SwapSetting[] public swapSettings;
    uint256[] public totalStaked;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when brews mining starts.
    uint256 public startBlock;

    uint256 private totalEarned;
    uint256 private totalRewardStaked;
    uint256 private totalReflectionStaked;
    uint256 private totalReflections;
    uint256 private reflectionDebt;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetBuyBackWallet(address indexed user, address newAddress);
    event SetPerformanceFee(uint256 fee);
    event UpdateEmissionRate(address indexed user, uint256 rewardPerBlock);

    constructor(IERC20 _brews, address _reflectionToken, uint256 _rewardPerBlock, bool _hasDividend) {
        brews = _brews;
        reflectionToken = _reflectionToken;
        rewardPerBlock = _rewardPerBlock;
        hasDividend = _hasDividend;

        feeAddress = msg.sender;
        startBlock = block.number.add(30 * 6219); // after 30 days
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFee, uint16 _withdrawFee, uint256 _duration, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        require(_depositFee <= 10000, "add: invalid deposit fee basis points");
        require(_withdrawFee <= 10000, "add: invalid withdraw fee basis points");

        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            duration: _duration,
            startBlock: lastRewardBlock,
            bonusEndBlock: lastRewardBlock.add(_duration.mul(6219)),
            lastRewardBlock : lastRewardBlock,
            accTokenPerShare : 0,
            accReflectionPerShare : 0,
            lastReflectionPerPoint: 0,
            depositFee : _depositFee,
            withdrawFee: _withdrawFee
        }));

        swapSettings.push();
        swapSettings[swapSettings.length - 1].lpToken = _lpToken;

        totalStaked.push(0);
    }

    // Update the given pool's brews allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFee, uint16 _withdrawFee, uint256 _duration, bool _withUpdate) external onlyOwner {
        require(_depositFee <= 10000, "set: invalid deposit fee basis points");
        require(_withdrawFee <= 10000, "set: invalid deposit fee basis points");
        if(poolInfo[_pid].bonusEndBlock > block.number) {
            require(poolInfo[_pid].startBlock.add(_duration.mul(6219)) > block.number, "set: invalid duration");
        }

        if (_withUpdate) {
            massUpdatePools();
        }
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].withdrawFee = _withdrawFee;
        poolInfo[_pid].duration = _duration;

        if(poolInfo[_pid].bonusEndBlock < block.number) {
            if (!_withUpdate) updatePool(_pid);
            
            poolInfo[_pid].startBlock = block.number;
            poolInfo[_pid].bonusEndBlock = block.number.add(_duration.mul(6219));
        } else {
            poolInfo[_pid].bonusEndBlock = poolInfo[_pid].startBlock.add(_duration.mul(6219));
        }
    }

    // Update the given pool's compound parameters. Can only be called by the owner.
    function setSwapSetting(
        uint256 _pid, 
        address _uniRouter, 
        address[] memory _earnedToToken0, 
        address[] memory _earnedToToken1, 
        address[] memory _reflectionToToken0, 
        address[] memory _reflectionToToken1, 
        bool _enabled
    ) external onlyOwner {
        SwapSetting storage swapSetting = swapSettings[_pid];

        swapSetting.enabled = _enabled;
        swapSetting.swapRouter = _uniRouter;
        swapSetting.earnedToToken0 = _earnedToToken0;
        swapSetting.earnedToToken1 = _earnedToToken1;
        swapSetting.reflectionToToken0 = _reflectionToToken0;
        swapSetting.reflectionToToken1 = _reflectionToToken1;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _endBlock) public pure returns (uint256) {
        if(_from > _endBlock) return 0;
        if(_to > _endBlock) {
            return _endBlock.sub(_from).mul(BONUS_MULTIPLIER);    
        }

        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending brews on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.bonusEndBlock);
            uint256 brewsReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(brewsReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function pendingReflections(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accReflectionPerShare = pool.accReflectionPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if(reflectionToken == address(pool.lpToken)) lpSupply = totalReflectionStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && hasDividend) {
            uint256 reflectionAmt = availableDividendTokens();
            if(reflectionAmt > totalReflections) {
                reflectionAmt = reflectionAmt.sub(totalReflections);
            } else reflectionAmt = 0;
            
            uint256 _accReflectionPerPoint = accReflectionPerPoint.add(reflectionAmt.mul(1e12).div(totalAllocPoint));
            
            accReflectionPerShare = pool.accReflectionPerShare.add(
                pool.allocPoint.mul(_accReflectionPerPoint.sub(pool.lastReflectionPerPoint)).div(lpSupply)
            );
        }
        return user.amount.mul(accReflectionPerShare).div(1e12).sub(user.reflectionDebt);
    } 

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if(reflectionToken == address(pool.lpToken)) lpSupply = totalReflectionStaked;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.bonusEndBlock);
        uint256 brewsReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accTokenPerShare = pool.accTokenPerShare.add(brewsReward.mul(1e12).div(lpSupply));

        if(hasDividend) {
            uint256 reflectionAmt = availableDividendTokens();
            if(reflectionAmt > totalReflections) {
                reflectionAmt = reflectionAmt.sub(totalReflections);
            } else reflectionAmt = 0;

            accReflectionPerPoint = accReflectionPerPoint.add(reflectionAmt.mul(1e12).div(totalAllocPoint));
            pool.accReflectionPerShare = pool.accReflectionPerShare.add(
                pool.allocPoint.mul(accReflectionPerPoint.sub(pool.lastReflectionPerPoint)).div(lpSupply)
            );
            pool.lastReflectionPerPoint = accReflectionPerPoint;

            totalReflections = totalReflections.add(reflectionAmt);
        }

        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to SpectreLabzFarm for brews allocation.
    function deposit(uint256 _pid, uint256 _amount) external payable nonReentrant {
        _transferPerformanceFee();

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if(pool.bonusEndBlock < block.number) {
            massUpdatePools();

            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
            pool.allocPoint = 0;
        } else {
            updatePool(_pid);
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                require(availableRewardTokens() >= pending, "Insufficient reward tokens");
                safeTokenTransfer(msg.sender, pending);

                if(totalEarned > pending) {
                    totalEarned = totalEarned.sub(pending);
                } else {
                    totalEarned = 0;
                }
            }

            uint256 pendingReflection = user.amount.mul(pool.accReflectionPerShare).div(1e12).sub(user.reflectionDebt);
            pendingReflection = _estimateDividendAmount(pendingReflection);
            if (pendingReflection > 0 && hasDividend) {
                if(address(reflectionToken) == address(0x0)) {
                    payable(msg.sender).transfer(pendingReflection);
                } else {
                    IERC20(reflectionToken).safeTransfer(msg.sender, pendingReflection);
                }
                totalReflections = totalReflections.sub(pendingReflection);
            }
        }
        if (_amount > 0) {
            uint256 beforeAmt = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterAmt = pool.lpToken.balanceOf(address(this));
            uint256 amount = afterAmt.sub(beforeAmt);

            if (pool.depositFee > 0) {
                uint256 depositFee = amount.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(amount);
            }

            _calculateTotalStaked(_pid, pool.lpToken, amount, true);
        }

        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.reflectionDebt = user.amount.mul(pool.accReflectionPerShare).div(1e12);

        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // Withdraw LP tokens from SpectreLabzFarm.
    function withdraw(uint256 _pid, uint256 _amount) external payable nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(_amount > 0, "Amount should be greator than 0");

        _transferPerformanceFee();

        if(pool.bonusEndBlock < block.number) {
            massUpdatePools();
            
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
            pool.allocPoint = 0;
        } else {
            updatePool(_pid);
        }

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            safeTokenTransfer(msg.sender, pending);

            if(totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }
        
        uint256 pendingReflection = user.amount.mul(pool.accReflectionPerShare).div(1e12).sub(user.reflectionDebt);
        pendingReflection = _estimateDividendAmount(pendingReflection);
        if (pendingReflection > 0 && hasDividend) {
            if(address(reflectionToken) == address(0x0)) {
                payable(msg.sender).transfer(pendingReflection);
            } else {
                IERC20(reflectionToken).safeTransfer(msg.sender, pendingReflection);
            }
            totalReflections = totalReflections.sub(pendingReflection);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (pool.withdrawFee > 0) {
                uint256 withdrawFee = _amount.mul(pool.withdrawFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, withdrawFee);
                pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(withdrawFee));
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }

            _calculateTotalStaked(_pid, pool.lpToken, _amount, false);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.reflectionDebt = user.amount.mul(pool.accReflectionPerShare).div(1e12);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claimReward(uint256 _pid) external payable nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.amount < 0) return;

        updatePool(_pid);
        _transferPerformanceFee();

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            safeTokenTransfer(msg.sender, pending);

            if(totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    }

    function compoundReward(uint256 _pid) external payable nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        SwapSetting memory swapSetting = swapSettings[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.amount < 0) return;
        if(!swapSetting.enabled) return;

        updatePool(_pid);
        _transferPerformanceFee();

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            if(totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        if(address(brews) != address(pool.lpToken)) {
            uint256 tokenAmt = pending / 2;
            uint256 tokenAmt0 = tokenAmt;
            address token0 = address(brews);
            if(swapSetting.earnedToToken0.length > 0) {
                token0 = swapSetting.earnedToToken0[swapSetting.earnedToToken0.length - 1];
                tokenAmt0 = _safeSwap(swapSetting.swapRouter, tokenAmt, swapSetting.earnedToToken0, address(this));
            }
            uint256 tokenAmt1 = tokenAmt;
            address token1 = address(brews);
            if(swapSetting.earnedToToken1.length > 0) {
                token0 = swapSetting.earnedToToken1[swapSetting.earnedToToken1.length - 1];
                tokenAmt1 = _safeSwap(swapSetting.swapRouter, tokenAmt, swapSetting.earnedToToken1, address(this));
            }

            uint256 beforeAmt = pool.lpToken.balanceOf(address(this));
            _addLiquidity(swapSetting.swapRouter, token0, token1, tokenAmt0, tokenAmt1, address(this));
            uint256 afterAmt = pool.lpToken.balanceOf(address(this));

            pending = afterAmt - beforeAmt;
        }

        user.amount = user.amount + pending;
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.reflectionDebt = user.reflectionDebt + pending * pool.accReflectionPerShare / 1e12;
        
        _calculateTotalStaked(_pid, pool.lpToken, pending, true);
        emit Deposit(msg.sender, _pid, pending);
    }

    function claimDividend(uint256 _pid) external payable nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.amount < 0) return;
        if(!hasDividend) return;
        
        updatePool(_pid);
        _transferPerformanceFee();

        uint256 pendingReflection = user.amount.mul(pool.accReflectionPerShare).div(1e12).sub(user.reflectionDebt);
        pendingReflection = _estimateDividendAmount(pendingReflection);
        if (pendingReflection > 0) {
            if(address(reflectionToken) == address(0x0)) {
                payable(msg.sender).transfer(pendingReflection);
            } else {
                IERC20(reflectionToken).safeTransfer(msg.sender, pendingReflection);
            }
            totalReflections = totalReflections.sub(pendingReflection);
        }

        user.reflectionDebt = user.amount.mul(pool.accReflectionPerShare).div(1e12);
    }

    function compoundDividend(uint256 _pid) external payable nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];
        SwapSetting memory swapSetting = swapSettings[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.amount < 0) return;
        if(!hasDividend) return;
        
        updatePool(_pid);
        _transferPerformanceFee();

        uint256 pending = user.amount.mul(pool.accReflectionPerShare).div(1e12).sub(user.reflectionDebt);
        pending = _estimateDividendAmount(pending);
        if (pending > 0) {
            totalReflections = totalReflections.sub(pending);
        }

        if(reflectionToken != address(pool.lpToken)) {
            if(reflectionToken == address(0x0)) {
                address wethAddress = IUniRouter02(swapSetting.swapRouter).WETH();
                IWETH(wethAddress).deposit{ value: pending }();
            }

            uint256 tokenAmt = pending / 2;
            uint256 tokenAmt0 = tokenAmt;
            address token0 = reflectionToken;
            if(swapSetting.reflectionToToken0.length > 0) {
                token0 = swapSetting.reflectionToToken0[swapSetting.reflectionToToken0.length - 1];
                tokenAmt0 = _safeSwap(swapSetting.swapRouter, tokenAmt, swapSetting.reflectionToToken0, address(this));
            }
            uint256 tokenAmt1 = tokenAmt;
            address token1 = reflectionToken;
            if(swapSetting.reflectionToToken1.length > 0) {
                token0 = swapSetting.reflectionToToken1[swapSetting.reflectionToToken1.length - 1];
                tokenAmt1 = _safeSwap(swapSetting.swapRouter, tokenAmt, swapSetting.reflectionToToken1, address(this));
            }

            uint256 beforeAmt = pool.lpToken.balanceOf(address(this));
            _addLiquidity(swapSetting.swapRouter, token0, token1, tokenAmt0, tokenAmt1, address(this));
            uint256 afterAmt = pool.lpToken.balanceOf(address(this));

            pending = afterAmt - beforeAmt;
        }

        user.amount = user.amount + pending;
        user.rewardDebt = user.rewardDebt + pending.mul(pool.accTokenPerShare).div(1e12);
        user.reflectionDebt = user.amount.mul(pool.accReflectionPerShare).div(1e12);

        _calculateTotalStaked(_pid, pool.lpToken, pending, true);        
        emit Deposit(msg.sender, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        _calculateTotalStaked(_pid, pool.lpToken, amount, false);
        
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas');

        payable(buyBackWallet).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    function _calculateTotalStaked(uint256 _pid, IERC20 _lpToken, uint256 _amount, bool _deposit) internal {
        if(_deposit) {
            totalStaked[_pid] = totalStaked[_pid].add(_amount);
            if(address(_lpToken) == address(brews)) {
                totalRewardStaked = totalRewardStaked + _amount;
            }
            if(address(_lpToken) == reflectionToken) {
                totalReflectionStaked = totalReflectionStaked + _amount;
            }
        } else {
            totalStaked[_pid] = totalStaked[_pid] - _amount;
            if(address(_lpToken) == address(brews)) {
                if(totalRewardStaked < _amount) totalRewardStaked = _amount;
                totalRewardStaked = totalRewardStaked - _amount;
            }
            if(address(_lpToken) == reflectionToken) {
                if(totalReflectionStaked < _amount) totalReflectionStaked = _amount;
                totalReflectionStaked = totalReflectionStaked - _amount;
            }
        }        
    }

    function _estimateDividendAmount(uint256 amount) internal view returns(uint256) {
        uint256 dTokenBal = availableDividendTokens();
        if(amount > totalReflections) amount = totalReflections;
        if(amount > dTokenBal) amount = dTokenBal;
        return amount;
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        if(address(brews) == reflectionToken) return totalEarned;

        uint256 _amount = brews.balanceOf(address(this));
        return _amount - totalRewardStaked;
    }

    /**
     * @notice Available amount of reflection token
     */
    function availableDividendTokens() public view returns (uint256) {
        if(address(reflectionToken) == address(0x0)) {
            return address(this).balance;
        }

        uint256 _amount = IERC20(reflectionToken).balanceOf(address(this));
        return _amount - totalReflectionStaked;
    }    

    // Safe brews transfer function, just in case if rounding error causes pool to not have enough brewss.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 brewsBal = brews.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > brewsBal) {
            transferSuccess = brews.transfer(_to, brewsBal);
        } else {
            transferSuccess = brews.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setPerformanceFee(uint256 _fee) external {
        require(msg.sender == buyBackWallet, "setPerformanceFee: FORBIDDEN");

        performanceFee = _fee;
        emit SetPerformanceFee(_fee);
    }
    
    function setBuyBackWallet(address _addr) external {
        require(msg.sender == buyBackWallet, "setBuyBackWallet: FORBIDDEN");
        buyBackWallet = _addr;
        emit SetBuyBackWallet(msg.sender, _addr);
    }

    //Brews has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit UpdateEmissionRate(msg.sender, _rewardPerBlock);
    }

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(startBlock > block.number, "farm is running now");
        require(_startBlock > block.number, "should be greater than current block");

        startBlock = _startBlock;
        for(uint pid = 0; pid < poolInfo.length; pid++) {
            poolInfo[pid].startBlock = startBlock;
            poolInfo[pid].lastRewardBlock = startBlock;
            poolInfo[pid].bonusEndBlock = startBlock.add(poolInfo[pid].duration.mul(6219));
        }
    }

    /*
     * @notice Deposit reward token
     * @dev Only call by owner. Needs to be for deposit of reward token when reflection token is same with reward token.
     */
    function depositRewards(uint _amount) external nonReentrant {
        require(_amount > 0);

        uint256 beforeAmt = brews.balanceOf(address(this));
        brews.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = brews.balanceOf(address(this));

        totalEarned = totalEarned.add(afterAmt).sub(beforeAmt);
    }

    function emergencyWithdrawRewards(uint256 _amount) external onlyOwner {
        if(_amount == 0) {
            uint256 amount = brews.balanceOf(address(this));
            safeTokenTransfer(msg.sender, amount);
        } else {
            safeTokenTransfer(msg.sender, _amount);
        }
    }

    function emergencyWithdrawReflections() external onlyOwner {
        if(address(reflectionToken) == address(0x0)) {
            uint256 amount = address(this).balance;
            payable(address(this)).transfer(amount);
        } else {
            uint256 amount = IERC20(reflectionToken).balanceOf(address(this));
            IERC20(reflectionToken).transfer(msg.sender, amount);
        }
    }

    function recoverWrongToken(address _token) external onlyOwner {
        require(_token != address(brews) && _token != reflectionToken, "cannot recover reward token or reflection token");
        require(poolExistence[IERC20(_token)] == false, "token is using on pool");

        if(_token == address(0x0)) {
            uint256 amount = address(this).balance;
            payable(address(this)).transfer(amount);
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            if(amount > 0) {
                IERC20(_token).transfer(msg.sender, amount);
            }
        }
    }

    function _safeSwap(
        address _uniRouter,
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal returns (uint256) {
        uint256 beforeAmt = IERC20(_path[_path.length - 1]).balanceOf(address(this));
        IERC20(_path[0]).safeApprove(_uniRouter, _amountIn);
        IUniRouter02(_uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            _path,
            _to,
            block.timestamp + 600
        );
        uint256 afterAmt = IERC20(_path[_path.length - 1]).balanceOf(address(this));
        return afterAmt - beforeAmt;
    }

    function _addLiquidity(
        address _uniRouter,
        address _token0,
        address _token1,
        uint256 _tokenAmt0,
        uint256 _tokenAmt1,
        address _to
    ) internal returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        IERC20(_token0).safeIncreaseAllowance(_uniRouter, _tokenAmt0);
        IERC20(_token1).safeIncreaseAllowance(_uniRouter, _tokenAmt1);

        (amountA, amountB, liquidity) = IUniRouter02(_uniRouter).addLiquidity(
            _token0,
            _token1,
            _tokenAmt0,
            _tokenAmt1,
            0,
            0,
            _to,
            block.timestamp + 600
        );

        IERC20(_token0).safeApprove(_uniRouter, uint256(0));
        IERC20(_token1).safeApprove(_uniRouter, uint256(0));
    }
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniRouter01.sol";

interface IUniRouter02 is IUniRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}