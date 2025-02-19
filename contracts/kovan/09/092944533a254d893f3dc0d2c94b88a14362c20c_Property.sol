/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Property{
    IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    event rateLog(address tokenAddr, uint256 rate);
    // event mortAmount(address recipient, address tokenAddr, uint256 rate);
    address tokenUSD;//当前抵押出的币种
    uint interRate;//年利率
    bool stateFrozen;
    bool notFrozenState;
    //冻结
    modifier notFrozen()
    {
        require(notFrozenState, "STATE_IS_FROZEN");
        _;
    }


    //预估需要的token，想兑换出数量amountOut, 那需要数量amountIn
    function sushiGetSwapTokenAmountIn(
        address tokenA,
        address tokenB,
        uint amountOut
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint amountIn = sushiRouter.getAmountsIn(
            amountOut,
            path
        )[0];
        return amountIn;
    }

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint amountOut = sushiRouter.getAmountsOut(
            amountIn,
            path
        )[0];
        return amountOut;
    }

    //开始兑换，把In兑换成Out，Out是稳定币，已在添加抵押物时approve
    function sushiSwapper(address tokenIn, address tokenOut,uint amountIn) private returns(uint){
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint amountOut = sushiGetSwapTokenAmountOut(tokenIn,tokenOut,amountIn);
        sushiRouter.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        return amountOut;
        // emit contraCollaLog();
    }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//设置新的抵押物
    mapping(address=>collaListPa) private collaList;//抵押物列表
    struct collaListPa{
        uint decimal;//小数
        uint mortRate;//抵押率
        uint liquRate;//清算率
        uint state;//启用状态
    }
    function setCollateralList(
        address tokenAddr,//抵押物地址
        uint decimal,
        uint mortRate,
        uint liquRate,
        uint state
    )public {
        if (collaList[tokenAddr].mortRate == 0){
            //polygon sushiswap address
            address sushiswapAddr = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
            //需要approve，this.address approve tokenA to sushiswap，清算时需要，否则无法清算卖出该币种
            IERC20 token = IERC20(tokenAddr);
            token.approve(sushiswapAddr,2**256-1);
        }
        collaList[tokenAddr].decimal = decimal;
        collaList[tokenAddr].mortRate = mortRate;
        collaList[tokenAddr].liquRate = liquRate;
        collaList[tokenAddr].state = state;
    }

//抵押出的币种
    address tokenUSDAddrOut;
    uint tokenUSDAddrOutDecimal;
    function settokenUSDAddr(address newtokenUSDAddr,uint newtokenUSDAddrOutDecimal) public{
        // emit tokenUSDchangeLog(newtokenUSDAddr,tokenUSDAddr);
        //核对现有的抵押物是否都有交易对，没有时抵押物应该禁用
        tokenUSDAddrOut = newtokenUSDAddr;
        tokenUSDAddrOutDecimal = newtokenUSDAddrOutDecimal;
    }

//年利率更改
    uint inteRate;
    uint inteRateDeno = 100000000000000000000;
    function setInteRate(uint newInteRate) public {
        //更新所有合同，不足8小时的不计，更新利息计时开始时间

        //更改利率
        interRate = newInteRate;
        // emit inteRateChangeLog(setInteRate,interRate);
    }

    //内部交易
    function transferToExchange(address tokenAddr,uint256 amount)public returns (bool){
        IERC20 token = IERC20(tokenAddr);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        // bytes memory callData = abi.encodeWithSelector(
        //     token.transferFrom.selector,
        //     msg.sender,
        //     address(this),
        //     amount
        // );
        // tokenAddr.call(callData);
        token.transferFrom(msg.sender, address(this), amount);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
        require(
            exchangeBalanceAfter == exchangeBalanceBefore + amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
        return true;
    }

//抵押物进来直接兑换，需要用户先approve到this.address
    //用户表
    mapping(address=>user) private users;
    struct user{
        mapping(address => uint) userAsset;//资金帐户
        // mapping(string=>contPar) userContList;//用户所有合同
        uint[] userContList;//合同编号列表
        // uint32 contNum;//合同总数
        uint userCreateTime;//创建时间
    }
    // struct contPar{
    //     address tokenUSD;
    //     uint createTime;
    //     uint state;
    // }

    //合同总数
    uint loanContractAmount;

    //合同表
    mapping(uint=>contListPar) contList;
    struct contListPar{
        address userAddr;//用户地址
        address mortAddr;//抵押物地址
        address tokenUSDAddr;//抵押出的币种地址
        uint mortAmount;//抵押物总数量
        uint tokenUSDAmount;//剩余抵押出的数量
        uint interestTime;//利息计时起始时间，每一次更新都会重置
        uint interestConfirm;//已确认的利息，每一次更新时累加
        mapping(uint=>contUpdateList) contUpdateList;//合同更新
        uint contUpdatelistNum;//更新次数，从0开始计数
        uint state;//合同状态，默认0，0正常，1：结算完成等待提出抵押物，2：抵押物已被提走，3：已被清算
        uint createTime;
    }
    struct contUpdateList{
        uint updateType;//更新类型，默认0，0：新开合同，1：追加，2：归还，3：抵押物提走，4：清算
        uint mortAmount;//抵押物数量
        uint tokenUSDAmount;//抵押出的数量
        uint mortRate;//抵押率
        // uint interestConfirm;//结算利息
        uint createTime;
    }

    function depositToken(
        address tokenAddr,
        uint amount
        // uint tranType
    )public notFrozen(){
        //判断抵押物是否存在，状态是否启用
        require(collaList[tokenAddr].state != 0,"MORTGAGE_INVALID");
        //transfer，转币到交易所合约地址
        transferToExchange(tokenAddr,amount);

        //查询抵押率，抵押出的币种
        uint mortRate = collaList[tokenAddr].mortRate;
        //可卖出币的数量
        uint tokenOutAmount = sushiGetSwapTokenAmountOut(tokenAddr,tokenUSDAddrOut,amount);
        //抵押出的数量
        uint tokenCollateraAmount = tokenOutAmount * mortRate/100;
        require(tokenCollateraAmount!=0,"TOKENOUTAMOUNT_TOO_LOW");

        uint isUser = users[msg.sender].userCreateTime;
        if (isUser==0) {//用户不存在
            users[msg.sender].userCreateTime = block.timestamp;
            // users[msg.sender].contNum = 1;
            // users[msg.sender].contList[newContId].tokenUSD = tokenUSDAddr;
            // users[msg.sender].contList[newContId].createTime = block.timestamp;
            // users[msg.sender].contList[newContId].state = tranType;

        }
        //资金帐户
        users[msg.sender].userAsset[tokenUSDAddrOut] += tokenCollateraAmount;
        //判断有没有合同，遍历所有合同
        bool contStateTemp = true;
        //合同编号
        //string memory newContId = string(string(abi.encodePacked(addressToSting(msg.sender),uint2str(idNum))));
        uint contId;
        uint contUpdatelistNum;
        for (uint i=0; i<=users[msg.sender].userContList.length;i++) {
            contId = users[msg.sender].userContList[i];
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint stateTemp = contList[contId].state;
            if (mortAddr==tokenAddr && tokenUSDAddr==tokenUSDAddrOut && stateTemp==0){
                //追加
                contStateTemp = false;
                contUpdatelistNum = contList[contId].contUpdatelistNum + 1;
                contList[contId].contUpdatelistNum = contUpdatelistNum;
                contList[contId].contUpdateList[contUpdatelistNum].updateType = 1;
                //小步结算利息 年利息为0.06时 rate=5479452054794520,20个零 100000000000000000000
                contList[contId].interestConfirm = getInterest(contId,1);

                break;
            }
        }
        //新合同
        if (contStateTemp){
            contId = loanContractAmount+1;
            contList[contId].userAddr = msg.sender;
            contList[contId].mortAddr = tokenAddr;
            contList[contId].tokenUSDAddr = tokenUSDAddrOut;
            contList[contId].createTime = block.timestamp;
            loanContractAmount ++;//合同总数加1
            users[msg.sender].userContList.push(contId);//新合同号加到用户列表
        }
        contList[contId].interestTime = block.timestamp;
        contList[contId].mortAmount += tokenCollateraAmount;
        contList[contId].tokenUSDAmount += tokenCollateraAmount;
        contList[contId].contUpdateList[contUpdatelistNum].mortAmount = amount;
        contList[contId].contUpdateList[contUpdatelistNum].tokenUSDAmount = tokenCollateraAmount;
        contList[contId].contUpdateList[contUpdatelistNum].mortRate = mortRate;
        contList[contId].contUpdateList[contUpdatelistNum].createTime = block.timestamp;
        
        //写入日志，抵押出的量，交易所查询上帐用
        // emit depositCollateraAmount(msg.sender,tokenAddr,amount,tranType,collateraRate,tokenOutAmount,tokenCollateraAmount);
    }

    //链的主币充值，如eth,matic


    //归还
    function repayment(uint contId,uint amount) public {
        //资金帐户还款
        require(contList[contId].createTime != 0, "CONTRACT_NOT_EXIST");
        require(contList[contId].state == 0, "CONTRACT_FINISH");
        address tokenAddr = contList[contId].tokenUSDAddr;
        require(users[msg.sender].userAsset[tokenAddr] >= amount, "ASSET_INSUFFICIENT");
        uint tokenUSDAmount = contList[contId].tokenUSDAmount;
        // uint interestAmount = contList[contId].interestConfirm + getInterest(contId);
        contList[contId].interestConfirm += getInterest(contId,0);

        uint contUpdatelistNum = contList[contId].contUpdatelistNum + 1;
        contList[contId].contUpdatelistNum = contUpdatelistNum;
        contList[contId].contUpdateList[contUpdatelistNum].updateType = 2;
        contList[contId].contUpdateList[contUpdatelistNum].createTime = block.timestamp;
        contList[contId].interestTime = block.timestamp;

        if (amount >= tokenUSDAmount + contList[contId].interestConfirm){
            //可以清算
            users[msg.sender].userAsset[tokenAddr] -= (tokenUSDAmount + contList[contId].interestConfirm);
            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
            contList[contId].state = 1;//结算完成，等待抵押物被提走
            //归还数量
            contList[contId].contUpdateList[contUpdatelistNum].tokenUSDAmount = (tokenUSDAmount + contList[contId].interestConfirm);
        }else{
            //只够还一部分
            if (amount>=tokenUSDAmount){
                contList[contId].tokenUSDAmount = 0;
                contList[contId].interestConfirm -= amount-tokenUSDAmount;
            }else{
                contList[contId].tokenUSDAmount -= amount;
            }
        }
    }

    //返回实时利息
    function getInterest(uint contId,uint addNum) internal view returns(uint){
        return contList[contId].tokenUSDAmount * ((block.timestamp - contList[contId].interestTime) / 3600 / 8 + addNum) * inteRate/inteRateDeno;
    }

    //返回需要清算合同
    function liquidateList(uint start,uint end)public view returns(uint[] memory){
        require(end>=start);
        require(end<=loanContractAmount);
        uint[] memory reLiqui;
        uint j;
        for (uint i=start; i<=end; i++){
            if(isLiqui(i)){
                reLiqui[j] = i;
                j++;
            }
        }
        return reLiqui;
    }

    //判断合同是否需要被清算
    function isLiqui(uint contId)private view returns(bool){
        if (contList[contId].state == 0){
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            //可卖出币的数量
            uint tokenOutAmount = sushiGetSwapTokenAmountOut(mortAddr,tokenUSDAddr,mortAmount);
            if (tokenOutAmount * collaList[mortAddr].liquRate/100 < tokenUSDAmount + interAmount){
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }

    //清算
    function liquiContract(uint contId) public {
        if (contList[contId].state == 0){
            address userAddr = contList[contId].userAddr;
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            
            uint amountOut = sushiSwapper(mortAddr,tokenUSDAddr,mortAmount);
            if (amountOut>=tokenUSDAmount+interAmount){
                //剩余的转入资金帐户
                users[userAddr].userAsset[tokenUSDAddr] += amountOut-tokenUSDAmount-interAmount;
            }else{
                //清算完不够还抵押

            }
            //清算完成
            contList[contId].state = 3;//已被清算
            contList[contId].mortAmount = 0;
            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
        }
    }
    //address to string
    function addressToSting(address addr) internal pure returns(string memory){
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '';
        stringBytes[0] = '';

        for (uint i=0;i<20;i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 *leftValue;
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue+48) : bytes1(leftValue+87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue+48) : bytes1(rightValue+87);
            stringBytes[2*i+3] = rightChar;
            stringBytes[2*i+2] = leftChar;
        }
        return string(stringBytes);
    }

    //uint to string
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}