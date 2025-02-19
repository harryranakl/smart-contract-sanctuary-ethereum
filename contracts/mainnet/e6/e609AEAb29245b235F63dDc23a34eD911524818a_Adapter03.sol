// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../IAdapter.sol";
import "../../lib/aavee/Aavee.sol";
import "../../lib/chai/ChaiExchange.sol";
import "../../lib/bprotocol/BProtocolAMM.sol";
import "../../lib/bzx/BZX.sol";
import "../../lib/smoothy/SmoothyV1.sol";
import "../../lib/uniswap/UniswapV1.sol";
import "../../lib/kyberdmm/KyberDmm.sol";
import "../../lib/jarvis/Jarvis.sol";
import "../../lib/lido/Lido.sol";
import "../../lib/makerpsm/MakerPsm.sol";
import "../../lib/augustus-rfq/AugustusRFQ.sol";
import "../../lib/synthetix/SynthetixAdapter.sol";

/**
 * @dev This contract will route call to:
 * 0 - ChaiExchange
 * 1 - UniswapV1
 * 2 - SmoothyV1
 * 3 - BZX
 * 4 - BProtocol
 * 5 - Aave
 * 6 - KyberDMM
 * 7 - Jarvis
 * 8 - Lido
 * 9 - MakerPsm
 * 10 - AugustusRFQ
 * 11 - Synthetix
 * The above are the indexes
 */

contract Adapter03 is
    IAdapter,
    ChaiExchange,
    UniswapV1,
    SmoothyV1,
    BZX,
    BProtocol,
    Aavee,
    KyberDmm,
    Jarvis,
    Lido,
    MakerPsm,
    AugustusRFQ,
    Synthetix
{
    using SafeMath for uint256;

    /*solhint-disable no-empty-blocks*/
    constructor(
        uint16 aaveeRefCode,
        address aaveeSpender,
        address uniswapFactory,
        address chai,
        address dai,
        address weth,
        address stETH
    )
        public
        WethProvider(weth)
        Aavee(aaveeRefCode, aaveeSpender)
        UniswapV1(uniswapFactory)
        ChaiExchange(chai, dai)
        Lido(stETH)
        MakerPsm(dai)
    {}

    /*solhint-enable no-empty-blocks*/

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256,
        Utils.Route[] calldata route
    ) external payable override {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 0) {
                //swap on ChaiExchange
                swapOnChai(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 1) {
                //swap on Uniswap
                swapOnUniswapV1(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 2) {
                //swap on Smoothy
                swapOnSmoothyV1(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 3) {
                //swap on BZX
                swapOnBzx(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 4) {
                //swap on BProtocol
                swapOnBProtocol(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 5) {
                //swap on aavee
                swapOnAavee(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 6) {
                //swap on KyberDmm
                swapOnKyberDmm(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 7) {
                //swap on Jarvis
                swapOnJarvis(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 8) {
                //swap on Lido
                swapOnLido(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 9) {
                //swap on MakerPsm
                swapOnMakerPsm(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 10) {
                //swap on augustusRFQ
                swapOnAugustusRFQ(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 11) {
                // swap on Synthetix
                swapOnSynthetix(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../lib/Utils.sol";

interface IAdapter {
    /**
     * @dev Certain adapters needs to be initialized.
     * This method will be called from Augustus
     */
    function initialize(bytes calldata data) external;

    /**
     * @dev The function which performs the swap on an exchange.
     * @param fromToken Address of the source token
     * @param toToken Address of the destination token
     * @param fromAmount Amount of source tokens to be swapped
     * @param networkFee NOT USED - Network fee to be used in this router
     * @param route Route to be followed
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    ) external payable;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAavee.sol";
import "../Utils.sol";

contract Aavee {
    struct AaveeDataV1 {
        address aToken;
    }

    uint16 public immutable refCodeV1;
    address public immutable spender;

    constructor(uint16 _refCode, address _spender) public {
        refCodeV1 = _refCode;
        spender = _spender;
    }

    function swapOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnAavee(fromToken, toToken, fromAmount, exchange, payload);
    }

    function buyOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        _swapOnAavee(fromToken, toToken, fromAmount, exchange, payload);
    }

    function _swapOnAavee(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload
    ) private {
        AaveeDataV1 memory data = abi.decode(payload, (AaveeDataV1));

        Utils.approve(spender, address(fromToken), fromAmount);

        if (address(fromToken) == address(data.aToken)) {
            require(IAaveToken(data.aToken).underlyingAssetAddress() == address(toToken), "Invalid to token");

            IAaveToken(data.aToken).redeem(fromAmount);
        } else if (address(toToken) == address(data.aToken)) {
            require(IAaveToken(data.aToken).underlyingAssetAddress() == address(fromToken), "Invalid to token");
            if (address(fromToken) == Utils.ethAddress()) {
                IAaveV1LendingPool(exchange).deposit{ value: fromAmount }(fromToken, fromAmount, refCodeV1);
            } else {
                IAaveV1LendingPool(exchange).deposit(fromToken, fromAmount, refCodeV1);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IChai.sol";
import "../Utils.sol";

contract ChaiExchange {
    address public immutable chai;
    address public immutable dai;

    constructor(address _chai, address _dai) public {
        chai = _chai;
        dai = _dai;
    }

    function swapOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnChai(fromToken, toToken, fromAmount);
    }

    function buyOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnChai(fromToken, toToken, fromAmount);
    }

    function _swapOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) private {
        Utils.approve(address(chai), address(fromToken), fromAmount);

        if (address(fromToken) == chai) {
            require(address(toToken) == dai, "Destination token should be dai");
            IChai(chai).exit(address(this), fromAmount);
        } else if (address(fromToken) == dai) {
            require(address(toToken) == chai, "Destination token should be chai");
            IChai(chai).join(address(this), fromAmount);
        } else {
            revert("Invalid fromToken");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IBProtocolAMM.sol";

contract BProtocol {
    function swapOnBProtocol(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IBProtocolAMM(exchange).swap(fromAmount, 1, payable(address(this)));
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IBZX.sol";
import "../Utils.sol";
import "../WethProvider.sol";

abstract contract BZX is WethProvider {
    struct BZXData {
        address iToken;
    }

    function swapOnBzx(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnBZX(fromToken, toToken, fromAmount, payload);
    }

    function buyOnBzx(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnBZX(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnBZX(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        BZXData memory data = abi.decode(payload, (BZXData));

        Utils.approve(address(data.iToken), address(fromToken), fromAmount);

        if (address(fromToken) == address(data.iToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                require(IBZX(data.iToken).loanTokenAddress() == WETH, "Invalid to token");
                IBZX(data.iToken).burnToEther(payable(address(this)), fromAmount);
            } else {
                require(IBZX(data.iToken).loanTokenAddress() == address(toToken), "Invalid to token");
                IBZX(data.iToken).burn(address(this), fromAmount);
            }
        } else if (address(toToken) == address(data.iToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                require(IBZX(data.iToken).loanTokenAddress() == WETH, "Invalid from token");

                IBZX(data.iToken).mintWithEther{ value: fromAmount }(address(this));
            } else {
                require(IBZX(data.iToken).loanTokenAddress() == address(fromToken), "Invalid from token");
                IBZX(data.iToken).mint(address(this), fromAmount);
            }
        } else {
            revert("Invalid token pair!!");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./ISmoothyV1.sol";
import "../weth/IWETH.sol";

contract SmoothyV1 {
    struct SmoothyV1Data {
        uint256 i;
        uint256 j;
    }

    function swapOnSmoothyV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SmoothyV1Data memory data = abi.decode(payload, (SmoothyV1Data));

        Utils.approve(exchange, address(fromToken), fromAmount);

        ISmoothyV1(exchange).swap(data.i, data.j, fromAmount, 1);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";

contract UniswapV1 {
    using SafeMath for uint256;

    address public immutable factory;

    constructor(address _factory) public {
        factory = _factory;
    }

    function swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnUniswapV1(fromToken, toToken, fromAmount, 1);
    }

    function buyOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) internal {
        address exchange = getExchange(fromToken, toToken);

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        if (address(fromToken) == Utils.ethAddress()) {
            IUniswapExchange(exchange).ethToTokenSwapOutput{ value: fromAmount }(toAmount, block.timestamp);
        } else if (address(toToken) == Utils.ethAddress()) {
            IUniswapExchange(exchange).tokenToEthSwapOutput(toAmount, fromAmount, block.timestamp);
        } else {
            IUniswapExchange(exchange).tokenToTokenSwapOutput(
                toAmount,
                fromAmount,
                Utils.maxUint(),
                block.timestamp,
                address(toToken)
            );
        }
    }

    function getExchange(IERC20 fromToken, IERC20 toToken) private view returns (address) {
        address exchangeAddress = address(fromToken) == Utils.ethAddress() ? address(toToken) : address(fromToken);

        return IUniswapFactory(factory).getExchange(exchangeAddress);
    }

    function _swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) private returns (uint256) {
        address exchange = getExchange(fromToken, toToken);

        Utils.approve(exchange, address(fromToken), fromAmount);

        uint256 receivedAmount = 0;

        if (address(fromToken) == Utils.ethAddress()) {
            receivedAmount = IUniswapExchange(exchange).ethToTokenSwapInput{ value: fromAmount }(
                toAmount,
                block.timestamp
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            receivedAmount = IUniswapExchange(exchange).tokenToEthSwapInput(fromAmount, toAmount, block.timestamp);
        } else {
            receivedAmount = IUniswapExchange(exchange).tokenToTokenSwapInput(
                fromAmount,
                toAmount,
                1,
                block.timestamp,
                address(toToken)
            );
        }

        return receivedAmount;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";
import "./IKyberDmmRouter.sol";

abstract contract KyberDmm is WethProvider {
    uint256 constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct KyberDMMData {
        address[] poolPath;
        IERC20[] path;
    }

    function swapOnKyberDmm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        KyberDMMData memory data = abi.decode(payload, (KyberDMMData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        IDMMExchangeRouter(exchange).swapExactTokensForTokens(
            fromAmount,
            1,
            data.poolPath,
            data.path,
            address(this),
            MAX_INT // deadline
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";

interface IJarvisPool {
    struct MintParams {
        // Derivative to use
        address derivative;
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Derivative to use
        address derivative;
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    struct ExchangeParams {
        // Derivative of source pool
        address derivative;
        // Destination pool
        address destPool;
        // Derivative of destination pool
        address destDerivative;
        // Amount of source synthetic tokens that user wants to use for exchanging
        uint256 numTokens;
        // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
        uint256 minDestNumTokens;
        // Maximum amount of fees in percentage that user is willing to pay
        uint256 feePercentage;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens exchanged
        address recipient;
    }

    function mint(MintParams memory mintParams) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    function redeem(RedeemParams memory redeemParams) external returns (uint256 collateralRedeemed, uint256 feePaid);

    function exchange(ExchangeParams memory exchangeParams)
        external
        returns (uint256 destNumTokensMinted, uint256 feePaid);
}

contract Jarvis {
    enum MethodType {
        mint,
        redeem,
        exchange
    }

    struct JarvisData {
        uint256 opType;
        address derivatives;
        address destDerivatives;
        uint128 fee;
        address destPool;
        uint128 expiration;
    }

    function swapOnJarvis(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        JarvisData memory data = abi.decode(payload, (JarvisData));
        Utils.approve(exchange, address(fromToken), fromAmount);

        if (data.opType == uint256(MethodType.mint)) {
            IJarvisPool.MintParams memory mintParam = IJarvisPool.MintParams(
                data.derivatives,
                1,
                fromAmount,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).mint(mintParam);
        } else if (data.opType == uint256(MethodType.redeem)) {
            IJarvisPool.RedeemParams memory redeemParam = IJarvisPool.RedeemParams(
                data.derivatives,
                fromAmount,
                1,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).redeem(redeemParam);
        } else if (data.opType == uint256(MethodType.exchange)) {
            IJarvisPool.ExchangeParams memory exchangeParam = IJarvisPool.ExchangeParams(
                data.derivatives,
                data.destPool,
                data.destDerivatives,
                fromAmount,
                1,
                data.fee,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).exchange(exchangeParam);
        } else {
            revert("Invalid opType");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IstETH.sol";

contract Lido {
    address public immutable stETH;

    constructor(address _stETH) public {
        stETH = _stETH;
    }

    function swapOnLido(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        require(address(fromToken) == Utils.ethAddress(), "srcToken should be ETH");
        require(address(toToken) == stETH, "destToken should be stETH");

        IstETH(stETH).submit{ value: fromAmount }(address(0));
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPsm.sol";
import "../Utils.sol";

contract MakerPsm {
    using SafeMath for uint256;
    address immutable daiMaker; // dai name has collision with chai
    uint256 constant WAD = 1e18;

    struct MakerPsmData {
        address gemJoinAddress;
        uint256 toll;
        uint256 to18ConversionFactor;
    }

    constructor(address _dai) public {
        daiMaker = _dai;
    }

    function swapOnMakerPsm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MakerPsmData memory makerPsmData = abi.decode(payload, (MakerPsmData));

        if (address(fromToken) == daiMaker) {
            uint256 gemAmt = fromAmount.mul(WAD).div(WAD.add(makerPsmData.toll).mul(makerPsmData.to18ConversionFactor));
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPsm(exchange).buyGem(address(this), gemAmt);
        } else {
            Utils.approve(makerPsmData.gemJoinAddress, address(fromToken), fromAmount);
            IPsm(exchange).sellGem(address(this), fromAmount);
        }
    }

    function buyOnMakerPsm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MakerPsmData memory makerPsmData = abi.decode(payload, (MakerPsmData));

        if (address(fromToken) == daiMaker) {
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPsm(exchange).buyGem(address(this), toAmount);
        } else {
            uint256 a = toAmount.mul(WAD);
            uint256 b = WAD.sub(makerPsmData.toll).mul(makerPsmData.to18ConversionFactor);
            // ceil division to handle rounding error
            uint256 gemAmt = (a.add(b).sub(1)).div(b);
            Utils.approve(makerPsmData.gemJoinAddress, address(fromToken), fromAmount);
            IPsm(exchange).sellGem(address(this), gemAmt);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAugustusRFQ.sol";
import "../Utils.sol";
import "../WethProvider.sol";
import "../weth/IWETH.sol";

abstract contract AugustusRFQ is WethProvider {
    using SafeMath for uint256;

    struct AugustusRFQData {
        IAugustusRFQ.OrderInfo[] orderInfos;
    }

    function swapOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            Utils.approve(exchange, WETH, fromAmount);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmount);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(data.orderInfos, fromAmount, address(this));

        if (address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }

    function buyOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmountMax,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmountMax }();
            Utils.approve(exchange, WETH, fromAmountMax);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmountMax);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(data.orderInfos, toAmount, address(this));

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

interface ISynthetix {
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount
    ) external returns (uint256 amountReceived);

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);
}

abstract contract Synthetix {
    // Atomic exchanges work only with sTokens, so no need to wrap/unwrap them

    struct SynthetixData {
        bytes32 trackingCode;
        bytes32 srcCurrencyKey;
        bytes32 destCurrencyKey;
        // 0 - exchangeAtomically
        // 1 - exchange
        int8 exchangeType;
    }

    function swapOnSynthetix(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SynthetixData memory synthetixData = abi.decode(payload, (SynthetixData));

        Utils.approve(exchange, address(fromToken), fromAmount);

        if (synthetixData.exchangeType == 0) {
            ISynthetix(exchange).exchangeAtomically(
                synthetixData.srcCurrencyKey,
                fromAmount,
                synthetixData.destCurrencyKey,
                synthetixData.trackingCode,
                1
            );
        } else {
            ISynthetix(exchange).exchange(synthetixData.srcCurrencyKey, fromAmount, synthetixData.destCurrencyKey);
        }
    }
}

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ITokenTransferProxy.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveToken {
    function redeem(uint256 amount) external;

    function underlyingAssetAddress() external view returns (address);
}

interface IAaveV1LendingPool {
    function deposit(
        IERC20 token,
        uint256 amount,
        uint16 refCode
    ) external payable;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IChai {
    function join(address dst, uint256 wad) external;

    function exit(address src, uint256 wad) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IBProtocolAMM {
    function swap(
        uint256 lusdAmount,
        uint256 minEthReturn,
        address payable dest
    ) external returns (uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IBZX {
    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount);

    function mintWithEther(address receiver) external payable returns (uint256 mintAmount);

    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);

    function burnToEther(address payable receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);

    function loanTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

contract WethProvider {
    /*solhint-disable var-name-mixedcase*/
    address public immutable WETH;

    /*solhint-enable var-name-mixedcase*/

    constructor(address weth) public {
        WETH = weth;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ISmoothyV1 {
    function swap(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount,
        uint256 bTokenOutMin
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IUniswapExchange {
    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) external payable returns (uint256 tokensBought);

    function ethToTokenSwapOutput(uint256 tokensBought, uint256 deadline) external payable returns (uint256 ethSold);

    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline
    ) external returns (uint256 ethBought);

    function tokenToEthSwapOutput(
        uint256 ethBought,
        uint256 maxTokens,
        uint256 deadline
    ) external returns (uint256 tokensSold);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddr
    ) external returns (uint256 tokensBought);

    function tokenToTokenSwapOutput(
        uint256 tokensBought,
        uint256 maxTokensSold,
        uint256 maxEthSold,
        uint256 deadline,
        address toToken
    ) external returns (uint256 tokensSold);

    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMExchangeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IstETH {
    function submit(address _referral) external payable returns (uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IPsm {
    function sellGem(address usr, uint256 gemAmt) external;

    function buyGem(address usr, uint256 gemAmt) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

interface IAugustusRFQ {
    struct Order {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        address makerAsset;
        address takerAsset;
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    // makerAsset and takerAsset are Packed structures
    // 0 - 159 bits are address
    // 160 - 161 bits are tokenType (0 ERC20, 1 ERC1155, 2 ERC721)
    struct OrderNFT {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        uint256 makerAsset;
        uint256 makerAssetId; // simply ignored in case of ERC20s
        uint256 takerAsset;
        uint256 takerAssetId; // simply ignored in case of ERC20s
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    struct OrderInfo {
        Order order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    struct OrderNFTInfo {
        OrderNFT order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    /**
     @dev Allows taker to fill complete RFQ order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrder(Order calldata order, bytes calldata signature) external;

    /**
     @dev Allows taker to fill Limit order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrderNFT(OrderNFT calldata order, bytes calldata signature) external;

    /**
     @dev Same as fillOrder but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Same as fillOrderNFT but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Allows taker to partially fill an order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Allows taker to partially fill an NFT order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrder` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTarget` but it allows to pass permit
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderNFT` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTargetNFT` but it allows to pass token permits
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermitNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Partial fill multiple orders
     @param orderInfos OrderInfo to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTarget(OrderInfo[] calldata orderInfos, address target) external;

    /**
     @dev batch fills orders until the takerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param takerFillAmount total taker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    ) external;

    /**
     @dev batch fills orders until the makerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param makerFillAmount total maker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    ) external;

    /**
     @dev Partial fill multiple NFT orders
     @param orderInfos Info about each order to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTargetNFT(OrderNFTInfo[] calldata orderInfos, address target) external;
}