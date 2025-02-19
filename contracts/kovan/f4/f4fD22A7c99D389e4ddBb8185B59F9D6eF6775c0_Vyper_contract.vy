# @version 0.2.4
# (c) Curve.Fi, 2020


# External Contracts
interface ERC20m:
    def totalSupply() -> uint256: view
    def allowance(_owner: address, _spender: address) -> uint256: view
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def mint(_to: address, _value: uint256): nonpayable
    def burn(_value: uint256): nonpayable
    def burnFrom(_to: address, _value: uint256): nonpayable
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def decimals() -> uint256: view
    def balanceOf(arg0: address) -> uint256: view
    def set_minter(_minter: address): nonpayable



# External Contracts
interface cERC20:
    def totalSupply() -> uint256: view
    def allowance(_owner: address, _spender: address) -> uint256: view
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def burn(_value: uint256): nonpayable
    def burnFrom(_to: address, _value: uint256): nonpayable
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def decimals() -> uint256: view
    def balanceOf(arg0: address) -> uint256: view
    def mint(mintAmount: uint256) -> uint256: nonpayable
    def redeem(redeemTokens: uint256) -> uint256: nonpayable
    def redeemUnderlying(redeemAmount: uint256) -> uint256: nonpayable
    def exchangeRateStored() -> uint256: view
    def exchangeRateCurrent() -> uint256: nonpayable
    def supplyRatePerBlock() -> uint256: view
    def accrualBlockNumber() -> uint256: view


from vyper.interfaces import ERC20


# Tether transfer-only ABI
interface USDT:
    def transfer(_to: address, _value: uint256): nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256): nonpayable


# This can (and needs to) be changed at compile time
N_COINS: constant(int128) = 4  # <- change

ZERO256: constant(uint256) = 0  # This hack is really bad XXX
ZEROS: constant(uint256[N_COINS]) = [ZERO256, ZERO256, ZERO256, ZERO256]  # <- change

USE_LENDING: constant(bool[N_COINS]) = [False, False, False, False]

# Flag "ERC20s" which don't return from transfer() and transferFrom()
TETHERED: constant(bool[N_COINS]) = [False, False, True, False]

FEE_DENOMINATOR: constant(uint256) = 10 ** 10
LENDING_PRECISION: constant(uint256) = 10 ** 18
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to
PRECISION_MUL: constant(uint256[N_COINS]) = [1, 1000000000000, 1000000000000, 1]
# PRECISION_MUL: constant(uint256[N_COINS]) = [
#     PRECISION / convert(PRECISION, uint256),  # DAI
#     PRECISION / convert(10 ** 6, uint256),   # USDC
#     PRECISION / convert(10 ** 6, uint256)]   # USDT


admin_actions_delay: constant(uint256) = 3 * 86400

# Events
event TokenExchange:
    buyer: indexed(address)
    sold_id: int128
    tokens_sold: uint256
    bought_id: int128
    tokens_bought: uint256

event TokenExchangeUnderlying:
    buyer: indexed(address)
    sold_id: int128
    tokens_sold: uint256
    bought_id: int128
    tokens_bought: uint256


event AddLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event RemoveLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    token_supply: uint256

event RemoveLiquidityImbalance:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event CommitNewAdmin:
    deadline: indexed(uint256)
    admin: indexed(address)

event NewAdmin:
    admin: indexed(address)

event CommitNewParameters:
    deadline: indexed(uint256)
    A: uint256
    fee: uint256
    admin_fee: uint256

event NewParameters:
    A: uint256
    fee: uint256
    admin_fee: uint256

coins_internal: address[N_COINS]
underlying_coins_internal: address[N_COINS]
balances_internal: uint256[N_COINS]
A: public(uint256)  # 2 x amplification coefficient
fee: public(uint256)  # fee * 1e10
admin_fee: public(uint256)  # admin_fee * 1e10

max_admin_fee: constant(uint256) = 5 * 10 ** 9
max_fee: constant(uint256) = 5 * 10 ** 9
max_A: constant(uint256) = 10 ** 6

syncer: public(address)
owner: public(address)
token: ERC20m

admin_actions_deadline: public(uint256)
transfer_ownership_deadline: public(uint256)
future_A: public(uint256)
future_fee: public(uint256)
future_admin_fee: public(uint256)
future_owner: public(address)

kill_deadline: uint256
kill_deadline_dt: constant(uint256) = 2 * 30 * 86400
is_killed: bool

last_mainnet_virtual_price: uint256

@external
def __init__(_syncer: address, _coins: address[N_COINS], _underlying_coins: address[N_COINS],
             _pool_token: address,
             _A: uint256, _fee: uint256):
    """
    _coins: Addresses of ERC20 conracts of coins (c-tokens) involved
    _underlying_coins: Addresses of plain coins (ERC20)
    _pool_token: Address of the token representing LP share
    _A: Amplification coefficient multiplied by n * (n - 1)
    _fee: Fee to charge for exchanges
    """
    for i in range(N_COINS):
        assert _coins[i] != ZERO_ADDRESS
        assert _underlying_coins[i] != ZERO_ADDRESS
        self.balances_internal[i] = 0
    self.coins_internal = _coins
    self.underlying_coins_internal = _underlying_coins
    self.A = _A
    self.fee = _fee
    self.admin_fee = 0
    self.owner = msg.sender
    self.syncer = _syncer
    self.kill_deadline = block.timestamp + kill_deadline_dt
    self.is_killed = False
    self.token = ERC20m(_pool_token)


@internal
@view
def _stored_rates() -> uint256[N_COINS]:
    # exchangeRateStored * (1 + supplyRatePerBlock * (getBlockNumber - accrualBlockNumber) / 1e18)
    result: uint256[N_COINS] = PRECISION_MUL
    use_lending: bool[N_COINS] = USE_LENDING
    for i in range(N_COINS):
        rate: uint256 = LENDING_PRECISION  # Used with no lending
        if use_lending[i]:
            rate = cERC20(self.coins_internal[i]).exchangeRateStored()
            supply_rate: uint256 = cERC20(self.coins_internal[i]).supplyRatePerBlock()
            old_block: uint256 = cERC20(self.coins_internal[i]).accrualBlockNumber()
            rate += rate * supply_rate * (block.number - old_block) / LENDING_PRECISION
        result[i] *= rate
    return result


@internal
def _current_rates() -> uint256[N_COINS]:
    result: uint256[N_COINS] = PRECISION_MUL
    use_lending: bool[N_COINS] = USE_LENDING
    for i in range(N_COINS):
        rate: uint256 = LENDING_PRECISION  # Used with no lending
        if use_lending[i]:
            rate = cERC20(self.coins_internal[i]).exchangeRateCurrent()
        result[i] *= rate
    return result


@internal
@view
def _xp(rates: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * self.balances_internal[i] / PRECISION
    return result


@internal
@view
def _xp_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * _balances[i] / PRECISION
    return result


@internal
@view
def get_D(xp: uint256[N_COINS]) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = self.A * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS + 1)  # +1 is to prevent /0
        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@internal
@view
def get_D_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256:
    return self.get_D(self._xp_mem(rates, _balances))

@external
@view
def balances(i: int128) -> uint256:
    return self.balances_internal[convert(i, uint256)]

@external
@view
def coins(i: int128) -> address:
    return self.coins_internal[convert(i, uint256)]

@external
@view
def underlying_coins(i: int128) -> address:
    return self.underlying_coins_internal[convert(i, uint256)]

@internal
@view
def get_virtual_price_internal() -> uint256:
    D: uint256 = self.get_D(self._xp(self._stored_rates()))
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    token_supply: uint256 = self.token.totalSupply()
    return D * PRECISION / token_supply

@external
@view
def get_virtual_price() -> uint256:
    """
    Returns portfolio virtual price (for calculating profit)
    scaled up by 1e18
    """
    return self.get_virtual_price_internal()


@external
@view
def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256:
    """
    Simplified method to calculate addition or reduction in token supply at
    deposit or withdrawal without taking fees into account (but looking at
    slippage).
    Needed to prevent front-running, not for precise calculations!
    """
    _balances: uint256[N_COINS] = self.balances_internal
    rates: uint256[N_COINS] = self._stored_rates()
    D0: uint256 = self.get_D_mem(rates, _balances)
    for i in range(N_COINS):
        if deposit:
            _balances[i] += amounts[i]
        else:
            _balances[i] -= amounts[i]
    D1: uint256 = self.get_D_mem(rates, _balances)
    token_amount: uint256 = self.token.totalSupply()
    diff: uint256 = 0
    if deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * token_amount / D0


@external
@nonreentrant('lock')
def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256):
    # Amounts is amounts of c-tokens
    assert not self.is_killed

    tethered: bool[N_COINS] = TETHERED
    use_lending: bool[N_COINS] = USE_LENDING
    fees: uint256[N_COINS] = ZEROS
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = self.admin_fee

    token_supply: uint256 = self.token.totalSupply()
    rates: uint256[N_COINS] = self._current_rates()
    # Initial invariant
    D0: uint256 = 0
    old_balances: uint256[N_COINS] = self.balances_internal
    if token_supply > 0:
        D0 = self.get_D_mem(rates, old_balances)
    new_balances: uint256[N_COINS] = old_balances

    for i in range(N_COINS):
        if token_supply == 0:
            assert amounts[i] > 0
        # balances store amounts of c-tokens
        new_balances[i] = old_balances[i] + amounts[i]

    # Invariant after change
    D1: uint256 = self.get_D_mem(rates, new_balances)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    D2: uint256 = D1
    if token_supply > 0:
        # Only account for fees if we are not the first to deposit
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            if ideal_balance > new_balances[i]:
                difference = ideal_balance - new_balances[i]
            else:
                difference = new_balances[i] - ideal_balance
            fees[i] = _fee * difference / FEE_DENOMINATOR
            self.balances_internal[i] = new_balances[i] - (fees[i] * _admin_fee / FEE_DENOMINATOR)
            new_balances[i] -= fees[i]
        D2 = self.get_D_mem(rates, new_balances)
    else:
        self.balances_internal = new_balances

    # Calculate, how much pool tokens to mint
    mint_amount: uint256 = 0
    if token_supply == 0:
        mint_amount = D1 * PRECISION / self.last_mainnet_virtual_price
    else:
        mint_amount = token_supply * (D2 - D0) / D0

    assert mint_amount >= min_mint_amount, "Slippage screwed you"

    # Take coins from the sender
    for i in range(N_COINS):
        if tethered[i] and not use_lending[i]:
            USDT(self.coins_internal[i]).transferFrom(msg.sender, self, amounts[i])
        else:
            cERC20(self.coins_internal[i]).transferFrom(msg.sender, self, amounts[i])

    # Mint pool tokens
    self.token.mint(msg.sender, mint_amount)

    log AddLiquidity(msg.sender, amounts, fees, D1, token_supply + mint_amount)


@internal
@view
def get_y(i: int128, j: int128, x: uint256, xp: uint256[N_COINS]) -> uint256:
    # x in the input is converted to the same price/precision

    assert (i != j) and (i >= 0) and (j >= 0) and (i < N_COINS) and (j < N_COINS)

    D: uint256 = self.get_D(xp)
    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = self.A * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i == i:
            _x = x
        elif _i != j:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D / (Ann * N_COINS)
    b: uint256 = S_ + D / Ann  # - D
    y_prev: uint256 = 0
    y: uint256 = D
    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                break
        else:
            if y_prev - y <= 1:
                break
    return y


@external
@view
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in c-units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + (dx * rates[i] / PRECISION)
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y) * PRECISION / rates[j]
    _fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return dy - _fee


@external
@view
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in underlying units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)
    precisions: uint256[N_COINS] = PRECISION_MUL

    x: uint256 = xp[i] + dx * precisions[i]
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y) / precisions[j]
    _fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return dy - _fee


@internal
def _exchange(i: int128, j: int128, dx: uint256, rates: uint256[N_COINS]) -> uint256:
    assert not self.is_killed
    # dx and dy are in c-tokens

    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + dx * rates[i] / PRECISION
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = xp[j] - y
    dy_fee: uint256 = dy * self.fee / FEE_DENOMINATOR
    dy_admin_fee: uint256 = dy_fee * self.admin_fee / FEE_DENOMINATOR
    self.balances_internal[i] = x * PRECISION / rates[i]
    self.balances_internal[j] = (y + (dy_fee - dy_admin_fee)) * PRECISION / rates[j]

    _dy: uint256 = (dy - dy_fee) * PRECISION / rates[j]

    return _dy


@external
@nonreentrant('lock')
def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256):
    rates: uint256[N_COINS] = self._current_rates()
    dy: uint256 = self._exchange(i, j, dx, rates)
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"
    tethered: bool[N_COINS] = TETHERED
    use_lending: bool[N_COINS] = USE_LENDING

    if tethered[i] and not use_lending[i]:
        USDT(self.coins_internal[i]).transferFrom(msg.sender, self, dx)
    else:
        cERC20(self.coins_internal[i]).transferFrom(msg.sender, self, dx)

    if tethered[j] and not use_lending[j]:
        USDT(self.coins_internal[j]).transfer(msg.sender, dy)
    else:
        cERC20(self.coins_internal[j]).transfer(msg.sender, dy)

    log TokenExchange(msg.sender, i, dx, j, dy)


@external
@nonreentrant('lock')
def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256):
    rates: uint256[N_COINS] = self._current_rates()
    precisions: uint256[N_COINS] = PRECISION_MUL
    rate_i: uint256 = rates[i] / precisions[i]
    rate_j: uint256 = rates[j] / precisions[j]
    dx_: uint256 = dx * PRECISION / rate_i

    dy_: uint256 = self._exchange(i, j, dx_, rates)
    dy: uint256 = dy_ * rate_j / PRECISION
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"
    use_lending: bool[N_COINS] = USE_LENDING
    tethered: bool[N_COINS] = TETHERED

    ok: uint256 = 0
    if tethered[i]:
        USDT(self.underlying_coins_internal[i]).transferFrom(msg.sender, self, dx)
    else:
        ERC20(self.underlying_coins_internal[i]).transferFrom(msg.sender, self, dx)
    if use_lending[i]:
        ERC20(self.underlying_coins_internal[i]).approve(self.coins_internal[i], dx)
        ok = cERC20(self.coins_internal[i]).mint(dx)
        if ok > 0:
            raise "Could not mint coin"
    if use_lending[j]:
        ok = cERC20(self.coins_internal[j]).redeem(dy_)
        if ok > 0:
            raise "Could not redeem coin"
    if tethered[j]:
        USDT(self.underlying_coins_internal[j]).transfer(msg.sender, dy)
    else:
        ERC20(self.underlying_coins_internal[j]).transfer(msg.sender, dy)

    log TokenExchangeUnderlying(msg.sender, i, dx, j, dy)


@external
@nonreentrant('lock')
def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]):
    total_supply: uint256 = self.token.totalSupply()
    amounts: uint256[N_COINS] = ZEROS
    fees: uint256[N_COINS] = ZEROS
    tethered: bool[N_COINS] = TETHERED
    use_lending: bool[N_COINS] = USE_LENDING

    for i in range(N_COINS):
        value: uint256 = self.balances_internal[i] * _amount / total_supply
        assert value >= min_amounts[i], "Withdrawal resulted in fewer coins than expected"
        self.balances_internal[i] -= value
        amounts[i] = value
        if tethered[i] and not use_lending[i]:
            USDT(self.coins_internal[i]).transfer(msg.sender, value)
        else:
            cERC20(self.coins_internal[i]).transfer(msg.sender, value)

    self.token.burnFrom(msg.sender, _amount)  # Will raise if not enough

    log RemoveLiquidity(msg.sender, amounts, fees, total_supply - _amount)


@external
@nonreentrant('lock')
def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256):
    assert not self.is_killed
    tethered: bool[N_COINS] = TETHERED
    use_lending: bool[N_COINS] = USE_LENDING

    token_supply: uint256 = self.token.totalSupply()
    assert token_supply > 0
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = self.admin_fee
    rates: uint256[N_COINS] = self._current_rates()

    old_balances: uint256[N_COINS] = self.balances_internal
    new_balances: uint256[N_COINS] = old_balances
    D0: uint256 = self.get_D_mem(rates, old_balances)
    for i in range(N_COINS):
        new_balances[i] -= amounts[i]
    D1: uint256 = self.get_D_mem(rates, new_balances)
    fees: uint256[N_COINS] = ZEROS
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        difference: uint256 = 0
        if ideal_balance > new_balances[i]:
            difference = ideal_balance - new_balances[i]
        else:
            difference = new_balances[i] - ideal_balance
        fees[i] = _fee * difference / FEE_DENOMINATOR
        self.balances_internal[i] = new_balances[i] - (fees[i] * _admin_fee / FEE_DENOMINATOR)
        new_balances[i] -= fees[i]
    D2: uint256 = self.get_D_mem(rates, new_balances)

    token_amount: uint256 = (D0 - D2) * token_supply / D0
    assert token_amount > 0
    assert token_amount <= max_burn_amount, "Slippage screwed you"

    for i in range(N_COINS):
        if tethered[i] and not use_lending[i]:
            USDT(self.coins_internal[i]).transfer(msg.sender, amounts[i])
        else:
            cERC20(self.coins_internal[i]).transfer(msg.sender, amounts[i])
    self.token.burnFrom(msg.sender, token_amount)  # Will raise if not enough

    log RemoveLiquidityImbalance(msg.sender, amounts, fees, D1, token_supply - token_amount)


### Admin functions ###
@external
def commit_new_parameters(amplification: uint256,
                          new_fee: uint256,
                          new_admin_fee: uint256):
    assert msg.sender == self.owner
    assert self.admin_actions_deadline == 0
    assert new_admin_fee <= max_admin_fee
    assert new_fee <= max_fee
    assert amplification <= max_A

    _deadline: uint256 = block.timestamp + admin_actions_delay
    self.admin_actions_deadline = _deadline
    self.future_A = amplification
    self.future_fee = new_fee
    self.future_admin_fee = new_admin_fee

    log CommitNewParameters(_deadline, amplification, new_fee, new_admin_fee)


@external
def apply_new_parameters():
    assert msg.sender == self.owner
    assert self.admin_actions_deadline <= block.timestamp\
        and self.admin_actions_deadline > 0

    self.admin_actions_deadline = 0
    _A: uint256 = self.future_A
    _fee: uint256 = self.future_fee
    _admin_fee: uint256 = self.future_admin_fee
    self.A = _A
    self.fee = _fee
    self.admin_fee = _admin_fee

    log NewParameters(_A, _fee, _admin_fee)


@external
def revert_new_parameters():
    assert msg.sender == self.owner

    self.admin_actions_deadline = 0


@external
def commit_transfer_ownership(_owner: address):
    assert msg.sender == self.owner
    assert self.transfer_ownership_deadline == 0

    _deadline: uint256 = block.timestamp + admin_actions_delay
    self.transfer_ownership_deadline = _deadline
    self.future_owner = _owner

    log CommitNewAdmin(_deadline, _owner)


@external
def apply_transfer_ownership():
    assert msg.sender == self.owner
    assert block.timestamp >= self.transfer_ownership_deadline\
        and self.transfer_ownership_deadline > 0

    self.transfer_ownership_deadline = 0
    _owner: address = self.future_owner
    self.owner = _owner

    log NewAdmin(_owner)


@external
def revert_transfer_ownership():
    assert msg.sender == self.owner

    self.transfer_ownership_deadline = 0


@external
def withdraw_admin_fees():
    assert msg.sender == self.owner
    _precisions: uint256[N_COINS] = PRECISION_MUL
    tethered: bool[N_COINS] = TETHERED
    use_lending: bool[N_COINS] = USE_LENDING

    for i in range(N_COINS):
        c: address = self.coins_internal[i]
        value: uint256 = cERC20(c).balanceOf(self) - self.balances_internal[i]
        if value > 0:
            if tethered[i] and not use_lending[i]:
                USDT(c).transfer(msg.sender, value)
            else:
                cERC20(c).transfer(msg.sender, value)


@external
def kill_me():
    assert msg.sender == self.owner
    assert self.kill_deadline > block.timestamp
    self.is_killed = True


@external
def unkill_me():
    assert msg.sender == self.owner
    self.is_killed = False

@external
def sync_pool(new_mainnet_virtual_price: uint256, _a: uint256):
    assert msg.sender == self.syncer

    token_supply: uint256 = self.token.totalSupply()

    if token_supply > 0:
        old_virtual_price: uint256 = self.get_virtual_price_internal()
        for i in range(N_COINS):
            self.balances_internal[i] = self.balances_internal[i] * new_mainnet_virtual_price / old_virtual_price

    self.last_mainnet_virtual_price = new_mainnet_virtual_price
    self.A = _a