# Security audit — CDAO token system (BNB Smart Chain)

Scope: `CDaoToken` (`0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0`) and every contract
in its resolved trust graph (see `README.md`). Question answered: **can a hostile,
unprivileged, well-resourced actor (flash loans, many addresses, atomic multi-step
txns, hostile-but-standards-compliant tokens, unlimited patience) take value or
seize control they weren't entitled to?** Snapshot: 2026-08-17, block ≈116.43M.

Method: mechanical enumeration of every externally-reachable entry point, then a
state-dependency/composition pass, audited against the **live deployed
configuration** (`AUTHORITY_AND_CONFIG.md`), not the abstract code.

---

## Verdict

**No unprivileged value-extraction or unauthorized-control finding survives
scrutiny in the readable contracts** (`CDaoToken`, `Token`/ProToken, `PancakePair`,
`CryptoTreasury`, `RBSControl`). Every value-moving or authority-granting function
in those is gated by a role that only the owner/governance/Safe can grant, with no
self-grant path, no missing guard, no forgeable signature, and no hardcoded secret.

**The decisive caveat, and the real risk surface, is a boundary this audit cannot
cross from the chain:** ProToken — CDAO's *only* liquidity counterparty, and thus
the thing that ultimately backs CDAO's on-chain value — is the reserve token of a
full **Olympus-DAO-fork** bonding/staking/treasury system whose three core
contracts (a reserve bond depository, an LP bond depository, and a staking
distributor) are **unverified bytecode holding live mint authority over ProToken**.
Their user-facing `deposit()` path is **permissionless** (confirmed empirically —
see Finding B). Whether an unprivileged bonder can mint ProToken for less than the
value they deposit — the one property that determines whether this whole system can
be drained — lives in that unaudited math. I could not rule an economic exploit in
or out there. Treat Finding B as the load-bearing conclusion; the clean result on
the readable code does **not** imply the system is sound.

Findings A and C are latent/centralization issues in readable code that are not
unprivileged-reachable today but materially shape the risk.

---

## System model (what backs value, where it enters/leaves, who may do what)

- **CDaoToken** is a fixed-supply (180,000,000, 9 decimals) ERC-20 minted entirely
  in its constructor — **no mint function exists**. Its custom logic is a
  transfer-tax / transfer-restriction layer keyed on one `targetPool`: sells into
  the pool burn `sellRatio` (currently 28%) to `dead`; buys out of the pool are
  currently **disabled** (`transferStatus=false`) for non-whitelisted addresses.
  Value cannot be created here; it can only be taxed/blocked. Those levers are
  owner/governance-only.
- **CDAO's only market** is the `PancakePair` at `0x86aC451a…`, paired **against
  ProToken, not BNB/USD**. So CDAO's price is a function of ProToken's price, which
  is set on a *separate* ProToken/BSC-USD pool. Draining or distorting CDAO value
  routes through ProToken.
- **ProToken** (`0x8D657445…`) is a near-identical token to CDAO **plus a
  `mint(to,amount)` gated to `treasury`**. Its `owner` is renounced (`dead`), so its
  `onlyOwner` levers are frozen; `onlyGovernance` levers sit behind an unverified
  proxy (see `UNRESOLVED.md`). ProToken **supply can grow**, and that is the only
  place new value enters the CDAO-facing side of the system.
- **`treasury`** = `CryptoTreasury` (behind `TreasuryProxy 0xf9074b5C…`), an
  Olympus-style reserve treasury. It mints ProToken to callers holding treasury
  roles, against deposited reserves (BSC-USD) or bonded LP. Roles are Safe-granted.
- **The roles that can make the treasury mint are held by three unverified
  Olympus-fork bond/distributor proxies** (Finding B). This is where value actually
  enters, and it is the part I cannot read.

**Safety properties honest users rely on:**
1. CDAO supply is fixed and no one can mint it. *(Holds — verified, no mint fn.)*
2. ProToken can only be minted in exchange for at-least-equal value. *(Cannot be
   verified — Finding B.)*
3. No unprivileged actor can grant themselves a treasury role, move funds they don't
   own, or upgrade a proxy. *(Holds for readable code; upgrade authority is a
   Safe/EOA centralization matter, out of scope as an attack.)*

---

## Artifact 1 — complete enumeration of externally-reachable entry points

Guard notation: `owner` = OZ `Ownable`/`OwnableUpgradeable` owner; `gov` =
`msg.sender==governance`; `treasury` = `msg.sender==treasury`; `role:X` = treasury
role mapping; `none` = permissionless. "Reachable by attacker?" judges an
*unprivileged* caller.

### CDaoToken — 0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0 (verified)

| Function | Guard | Reachable? | Why it isn't exploitable |
|---|---|---|---|
| `constructor()` | n/a | one-time | Ran at deploy; mints fixed supply to deployer. Not re-callable. |
| `transfer` / `transferFrom` / `approve` | none | yes | Standard ERC-20; only move caller's own balance/allowance. `_update` tax/restriction only subtracts/blocks, never credits a third party. |
| `_update` (via transfers) | none | yes | Tax burns to `dead`; restriction reverts. No path credits value to anyone. |
| `addWhitelist`/`removeWhitelist` | owner | no | Owner-only exemption list. Can't self-add. |
| `setTargetPool` | owner | no | Owner-only. |
| `setTargetRatio` | gov | no | Governance-only; and `governance` is a proxy with no code path back into CDAO (dormant). |
| `setTransferState` | owner | no | Owner-only honeypot lever; owner's own power over own token. |
| `transferGovernance` | owner | no | Owner-only. |
| `setSellRates` | owner | no | Owner-only; **no upper bound** — owner can set >100% to freeze sells (honeypot), but that's owner power, not attacker gain. |
| `balancePool` | gov | no | Governance-only; dormant (current gov impl never calls it). |
| `owner`/`renounceOwnership`/`transferOwnership` | owner | no | Standard OZ. |
| public getters (`whitelist`,`governance`,`targetPool`,`targetRatio`,`transferStatus`,`sellRatio`,`base_100`,`lastBalanceTime`,`cooldownTime`,`deadAddress`,`decimals`,`name`,`symbol`,`totalSupply`,`balanceOf`,`allowance`) | none | yes (view) | Read-only. |

### Token / "ProToken" — 0x8D65744527f55d0b2338350912d5C99A81ddF0e2 (verified)

| Function | Guard | Reachable? | Why it isn't exploitable |
|---|---|---|---|
| ERC-20 core + `_update` | none | yes | As CDAO; sell tax to `feeReceiver`, restriction reverts. No credit path. |
| `mint(to,amount)` | `treasury` | no | Only the treasury proxy can mint. This is the crux — see Finding B for what stands behind `treasury`. |
| `addWhitelist`/`removeWhitelist`/`setTargetPool`/`setTreasury`/`setTargetRatio`/`setTransferState`/`transferGovernance` | owner | **frozen** | `owner` renounced to `dead` — these can never be called again. |
| `setFeeReceiver`/`setSellRates`/`balancePool` | gov | no | Governance = unverified proxy `0x96079eF9…` (see `UNRESOLVED.md`). Not attacker-reachable, but the impl is unread. |
| public getters | none | yes (view) | Read-only. |

### PancakePair — 0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df (verified, byte-identical to canonical V2)

| Function | Guard | Reachable? | Why it isn't exploitable |
|---|---|---|---|
| `mint`/`burn`/`swap`/`skim`/`sync` | none | yes | Standard V2 with the K-invariant check on `swap` (verified unmodified against the first pair the PancakeSwap factory ever created). Fee-on-transfer of CDAO/ProToken is normal FoT behavior; the K check still holds on realized balances. `transferStatus=false` makes buys-out revert (illiquid), which blocks — not enables — extraction. |
| `initialize` | factory-only | no | Guarded to factory. |
| LP ERC-20 + `permit` | none | yes | Standard EIP-2612; only moves caller's own LP. |
| getters (`getReserves`,`token0/1`,`price*CumulativeLast`,`kLast`,`factory`,…) | none | yes (view) | Read-only. |

### CryptoTreasury — impl 0xE6fa68BA… behind TreasuryProxy 0xf9074b5C… (verified)

| Function | Guard | Reachable? | Why it isn't exploitable (today) |
|---|---|---|---|
| `initialize` | `initializer` | no | Already initialized (owner=Safe). Impl's own storage init is inert (no delegatecall/selfdestruct in impl). |
| `setRbsContract` | owner | no | Owner-only. |
| `depositStableReserve(_token,_amount,_profit)` | `role: rbs \|\| reserveDepositor` | no | Mints `valueOf(_token,_amount) − _profit` to caller. Gated; `rbs`=RBSControl proxy, `reserveDepositor`s = the 3 unverified bond proxies. Bounded by deposited value. See Finding A/B. |
| `depositBondReserve(_token,_amount,_profit)` | `role: liquidityDepositor` + `isLiquidityToken` | no | Mints `bondCalculator.valuation(_token,_amount) − _profit`; burns the bonded LP. Gated. |
| `destroyBondReserve(_token,_amount,_profit)` | `role: reserveDepositor` + `isReserveToken` | no | **Mints attacker-supplied `_profit` directly, with `_amount` allowed to be 0** — an unbounded mint. Only gated by `reserveDepositor` (the unverified bond proxies). See Finding A. |
| `mintRewards(_recipient,_amount)` | `role: rewardManager` | no | Mints up to `excessReserves()` to `_recipient`. Gated to the distributor proxy. |
| `auditReserves` | owner | no | Recomputes `totalReserves` from balances. Owner-only. |
| `queue`/`toggle` | owner | no | The only way to grant any treasury role. Owner-only. **`blocksNeededForQueue=1`** → effectively no timelock (Finding C). |
| `supplied`/`excessReserves`/`valueOf` + array/mapping getters | none | yes (view) | Read-only. |

### RBSControl — impl 0xD50Eda29… behind GovernanceProxy 0xc2D8595… (verified)

| Function | Guard | Reachable? | Why it isn't exploitable |
|---|---|---|---|
| `initialize` | `initializer` | no | Already initialized (owner = hot EOA `0xe561…`). |
| `swap`/`addLiquidity`/`removeLiquidity`/`burnLP`/`burnCPLP` | owner | no | Owner-only; all send proceeds/`to` = `address(this)` or `dead`, never to an arbitrary external address. Even the 59.16M CDAO parked at this proxy can only be routed through the pool by the owner, not extracted by anyone else. |
| `mint(_usdAmount,_profit)` | owner | no | Owner-only; pulls this contract's own USD, calls `treasury.depositStableReserve` (RBSControl is `rbs`), mints ProToken to itself. Rate-limited 30 min, cap 200k. |
| views (`getAmountsIn/Out`,`getTokenPrice`,`getAmountForPair`,`estimateLiquidityAmount*`,`quote`,`calculateLiquidityAmount`) | none | yes (view) | Read-only pricing helpers; no state change. |
| Ownable (`owner`,`transferOwnership`,`renounceOwnership`) | owner | no | Standard. |

### Standard / out-of-scope-as-code infrastructure (guards, not re-audited)

- `TransparentUpgradeableProxy` shells + `ProxyAdmin` (OZ v5.5.0) — upgrade gated to
  the Safe. `GnosisSafe` 19-of-32 — standard. These are authority, covered in
  `AUTHORITY_AND_CONFIG.md`; their *powers* are privileged (out of scope as attacks).

### Unverified contracts in the value path (cannot enumerate from source)

- Reserve bond depository impl `0x03a05f1b…` (behind reserveDepositors `0xd337…`,
  `0xC56D…`, `0xaa04…`)
- LP bond depository impl `0xa394dcc7…` (behind liquidityDepositors `0x941D…`,
  `0x59dF…`, `0x7365…`, `0x510E…`)
- Staking distributor impl `0x62e52600…` (behind reward/reserve manager `0x7B09…`)

Selectors recovered from bytecode confirm these are Olympus V1 forks
(`deposit(uint256,uint256,address)`, `redeem`, `bondPriceInUSD`, `debtRatio`,
`maxPayout`, `distribute`, `adjustments`, …). Full entry-point enumeration is
**not possible** without source. See Finding B.

---

## Artifact 2 — state-dependency map and composition analysis

Format: **writer → state → reader**, then the compositions/sequences examined and
why each is safe (or the finding it yields).

### CDaoToken

- `setTargetPool/addWhitelist/removeWhitelist/setTransferState/setSellRates` (owner)
  and `setTargetRatio` (gov) **write** `targetPool / whitelist / transferStatus /
  sellRatio / targetRatio`; `_update` and `balancePool` **read** them.
  - *Composition A→B (shift then harvest):* every writer is owner/gov-only, so an
    unprivileged actor can't move the state a reader trusts. No pairing opens.
  - *`balancePool` reads `balanceOf(targetPool)` + `lastBalanceTime` (cooldown):*
    gov-only and dormant. Even if called, it burns pool tokens to `dead` and
    `sync()`s — it lowers the pool's CDAO, moving price against a seller, not
    minting to anyone.
- *Repetition/rounding:* the only arithmetic is `sellfeeAmount = amount*sellRatio/1e4`
  (rounds **down**, favoring the seller by dust, capped by `>= amount` revert) — no
  accumulator that splitting could farm. `balancePool` burn `= balanceOf(pool)*ratio/1e4`
  is idempotent per cooldown.

### PancakePair (external reserves as shared state)

- `swap/mint/burn/sync/skim` **write** reserves; `RBSControl.getTokenPrice /
  getAmountForPair / estimateLiquidityAmount` and any external pricing **read** them.
  - *Borrow-distort-then-price (classic oracle manip):* the only in-repo readers of
    pool reserves are RBSControl **view** helpers and its owner-only actions. An
    attacker can move reserves with a flash loan, but the function that would price
    off the distorted reserve (`RBSControl.swap/addLiquidity`) is `onlyOwner` — the
    attacker can't invoke the reader. The treasury does **not** price CDAO/ProToken
    pool reserves for its stable mint (`valueOf` uses decimals, not the pool). So no
    unprivileged distort-then-read pair closes **inside the readable code.** (The
    LP-bond depository *does* value LP via a `bondCalculator` off pool reserves —
    but that's unverified; Finding B.)

### CryptoTreasury (the mint engine)

- `toggle/setRbsContract` (owner) **write** `isReserveDepositor / isLiquidityDepositor
  / isRewardManager / rbs / bondCalculator / isReserveToken / isLiquidityToken`;
  every deposit/mint function **reads** them as its guard.
  - *Self-grant?* No. The only writer is `toggle`/`setRbsContract`, both `onlyOwner`.
    An attacker cannot enter any role. This is the single fact that keeps the entire
    mint surface closed to unprivileged callers **at the treasury boundary**.
- `depositStableReserve/depositBondReserve/destroyBondReserve` **write**
  `totalReserves` (+value) and mint ProToken; `excessReserves`→`mintRewards`
  **reads** `totalReserves` and `supplied()` (=`ProToken.totalSupply()`).
  - *Deposit-then-mintRewards:* inflating `totalReserves` to unlock more
    `mintRewards` requires a gated deposit; `mintRewards` is gated too. No
    unprivileged pairing.
  - *`valueOf` decimals path:* `value = amount * 1e9 / 1e(tokenDecimals)`. For
    BSC-USD (18d) → `amount/1e9`; amounts `< 1e9` wei round to **0** value → 0 mint.
    Splitting a deposit into dust **loses** (each sub-1e9 slice mints 0), so
    repetition is strictly unfavorable — no split-to-profit. And it's gated.
  - *`destroyBondReserve` unbounded `_profit`:* the reader of `isReserveDepositor`
    trusts a role the attacker can't hold. This is Finding A — dangerous by design,
    closed only by the role gate, whose holders are unverified (Finding B).
- *Reentrancy:* deposit fns call `safeTransferFrom`(reserve/LP token) → `mint`
  (ProToken, no attacker callback) → `safeTransfer(dead)`. Reserve/LP tokens are
  owner-set (BSC-USD, ProToken, the LP pair) — no attacker-controlled token with a
  hostile callback can be inserted (that insertion is `toggle`, owner-only). No
  unprivileged reentrancy.

### RBSControl

- `swap/addLiquidity/removeLiquidity/mint` **write** this contract's token balances
  and (via router) pool reserves; its views **read** balances/reserves. All writers
  are `onlyOwner`. No unprivileged writer, so no composition an attacker can stage.
  The cross-contract edge `RBSControl.mint → treasury.depositStableReserve` is gated
  twice (RBSControl `onlyOwner`, treasury `rbs`).

### Cross-contract value chain (the one that matters)

`bond deposit (permissionless) → treasury mints ProToken → ProToken supply ↑ →
ProToken/BSC-USD pool & CDAO/ProToken pool prices shift`. Every readable hop is
gated **except the first**, which lives in unverified bytecode. That is exactly why
the verdict rests on Finding B.

---

## Findings

### Finding A — `CryptoTreasury.destroyBondReserve` mints an unbounded, caller-supplied `_profit` (latent; role-gated today) — informational/centralization

`destroyBondReserve(address _token, uint256 _amount, uint256 _profit)`:
```solidity
require(isReserveToken[_token] && isReserveDepositor[msg.sender], "Not approved");
uint256 balance = IERC20(_token).balanceOf(msg.sender);
require(balance >= _amount, "Insufficient balance");
IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
_permissionMint(msg.sender, _profit);   // mints _profit ProToken to caller
IERC20(_token).safeTransfer(dead, _amount);
```
`_profit` is caller-controlled and minted directly; `_amount` may be `0` (then
`balance >= 0` is trivially true and both transfers move nothing). So **any holder
of the `reserveDepositor` role can mint arbitrary ProToken for free.** This breaks
safety property 2 for anyone who reaches the role.

*Why it's not an unprivileged finding today:* `isReserveDepositor` is set only by
`toggle` (`onlyOwner`=Safe). The three current holders are the unverified bond
proxies (Finding B). An unprivileged attacker cannot hold the role.

*Why it still matters:* it's an unbounded-mint primitive one role-grant away from
catastrophe, and the grant has **no timelock** (Finding C). If any `reserveDepositor`
bond contract has a bug that lets an unprivileged caller reach a path that forwards
into `destroyBondReserve` with attacker-chosen `_profit`, this is an instant,
capital-independent drain of ProToken (→ dump on the USD pool). Minimal fix:
`destroyBondReserve` should derive payout from `valueOf(_token,_amount)` like the
other paths, never accept `_profit` as a free mint; and require `_amount > 0`.

### Finding B — ProToken mint authority is exercised by unverified Olympus-fork bond/staking contracts with a permissionless `deposit()`; the mint-fairness math cannot be audited from chain — **decisive boundary, possible economic exploit unresolved**

`ProToken.mint` is gated to `treasury`; the treasury mints to holders of
`reserveDepositor` / `liquidityDepositor` / `rewardManager`. Those roles are held by
three proxies whose implementations are **unverified**:

| Role | Proxy(ies) | Unverified impl | Recovered identity |
|---|---|---|---|
| reserveDepositor ×3 | `0xd337…`,`0xC56D…`,`0xaa04…` | `0x03a05f1b…` | Olympus reserve **BondDepository** (`bondInfo`,`terms`,`bondPriceInUSD`,`principle`,`pendingPayoutFor`) |
| liquidityDepositor ×4 | `0x941D…`,`0x59dF…`,`0x7365…`,`0x510E…` | `0xa394dcc7…` | Olympus LP **BondDepository** (`deposit(uint256,uint256,address)`,`redeem`,`debtRatio`,`maxPayout`,`isLiquidityBond`,`bondCalculator`) |
| rewardManager | `0x7B09…` | `0x62e52600…` | Olympus **StakingDistributor** (`distribute`,`epoch`,`addRecipient`,`adjustments`,`nextRewardAt`) |

**Empirical reachability (the part I could establish):** calling
`deposit(uint256,uint256,address)` on LP-bond proxy `0x941D…` from an arbitrary
unprivileged address does **not** hit the owner guard — it reverts with a
fork-specific custom error `0x5e23f093` deep in the deposit logic (an OZ owner
rejection would be `0x118cdaa7`). So **the bond `deposit` path is open to anyone**,
exactly as Olympus bonding intends. Bond terms are controlled by a single EOA
(`0x8533e14Caea7C622A1Dc69B9eb5f0e47b79CE6A7`).

**What this means and what I could not resolve:** an unprivileged user can bond an
asset and receive newly-minted ProToken priced by `bondPriceInUSD` / `debtRatio` /
`maxPayout` / the LP `bondCalculator`, then the depository mints via the treasury.
Whether the payout can exceed the value deposited — through a debt-ratio or
bond-price miscalculation, a manipulable LP `bondCalculator` valuation (LP bonds
price off pool reserves an attacker *can* move with a flash loan), a decimals
mismatch, or a rounding/repetition edge — **is the entire ballgame for this
system's solvency, and it is unverified bytecode.** If it is exploitable, the attack
is: flash-loan/deposit to mint ProToken below cost → sell ProToken into the
ProToken/BSC-USD pool for profit → the same supply shock reprices the CDAO/ProToken
pool that values the audit target. This would be a disproportionate, capital-return
economic exploit realized through ordinary swaps (in scope: the cash-out swap is not
the bug).

I did not confirm such a bug — I could not read the code to confirm or refute it.
The clean result on the readable contracts must **not** be read as "the system is
safe to mint against." To close this, obtain the three implementations' source (or
decompile `0x03a05f1b…`, `0xa394dcc7…`, `0x62e52600…`) and audit the Olympus bond
math and the LP `bondCalculator` valuation against flash-loan reserve manipulation.

### Finding C — no timelock on treasury role grants (`blocksNeededForQueue = 1`) — centralization/defense-in-depth

`CryptoTreasury.queue` sets an activation block of `block.number + 1`; `toggle`
activates once `queue_[addr] <= block.number`. With the delay at **1 block**, the
owner can `queue` then `toggle` a new `reserveDepositor` (i.e., a new unbounded-mint
authority via Finding A) in **consecutive blocks** with no observation window.
Olympus deployments historically used a multi-thousand-block queue precisely so the
community can react to a malicious depositor grant. Here that protection is nominal.
This is owner power (out of scope as an *attack*) but it removes the only speed bump
in front of Finding A. Minimal fix: set a meaningful `blocksNeededForQueue`.

---

## Assumptions, boundaries, and what would change the verdict

- **Unverified implementations (Finding B) are the biggest gap.** If their source
  turns out clean (standard Olympus math, non-manipulable calculator), the system's
  value security holds and the verdict is "no finding, heavily centralized." If it's
  flawed, Finding B becomes a critical economic drain. I assumed nothing about their
  internals beyond the selectors/behavior recovered from bytecode and one deposit
  simulation.
- **Two further unverified proxies** — ProToken's governance impl `0xfdbf6f…` and
  the unnamed `0x6d694ce9…` (see `UNRESOLVED.md`) — were not readable. ProToken's
  gov controls `setSellRates`/`setFeeReceiver`/`balancePool`; a hostile impl there is
  a *privileged* (governance) power, not an unprivileged path, but its code is unread.
- **Event history was unavailable** (Etherscan V2 account/logs/proxy modules
  paywalled for chain 56; public RPC `eth_getLogs` range-capped — see `UNRESOLVED.md`
  item 4). So I audited *current* state and code, not the historical sequence of
  role grants. If a role was granted to an attacker-controlled contract in the past
  and not revoked, that would be visible only in logs I couldn't pull; the current
  role-holder set (all bond/distributor proxies) is what I verified live.
- **The governance-proxy storage/behavior mismatch** (`UNRESOLVED.md` item 1) does
  not affect these findings — RBSControl's functions are `onlyOwner` regardless of
  the slot oddity.
- **Configuration checked for coherence:** CDAO `sellRatio=2800`,`base_100=10000`,
  `targetRatio=200`(≤500 cap), `transferStatus=false`; ProToken `sellRatio=250`,
  `targetRatio=500`(=cap); treasury `blocksNeededForQueue=1`, `reserveTokens=[BSC-USD,
  ProToken]`, `usd=BSC-USD`, decimals 18→9 in `valueOf`. No parameter combination
  opens a path in the *readable* code that the code alone would have closed, except
  that `blocksNeededForQueue=1` makes the queue timelock vacuous (Finding C). The
  parameter I most want and don't have is the bond terms (control variable, debt
  ratio, max payout) inside the unverified depositories — those are the config that
  decides Finding B.

## Excluded (per scope)

Front-running/sandwiching, other users trading mid-exploit, and privileged parties
misusing legitimate powers (the Safe upgrading proxies; the RBSControl hot-EOA
routing its own CDAO; the bond-terms EOA setting prices) are out of scope. Note the
carve-out that kept Finding B **in** scope: an unprivileged bond deposit that mints
unfairly is a code/economic flaw even though its cash-out is an ordinary swap.
