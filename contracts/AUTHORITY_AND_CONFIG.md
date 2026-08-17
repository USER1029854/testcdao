# Live authority & configuration state

Snapshot taken 2026-08-17 (block ≈116,429,881 on BNB Smart Chain, chain ID 56),
via direct `eth_call`/`eth_getStorageAt` against public BSC RPC nodes
(`bsc.publicnode.com`, `bsc-mainnet.public.blastapi.io`, `bsc-dataseed{1..4}.binance.org`),
cross-validated across at least 2 independent providers for every value below
unless noted. Etherscan V2's `account`/`logs`/`proxy` API modules are paywalled
for chain 56 on the supplied key, so all of this was read directly from the
chain rather than through a block-explorer API — see `UNRESOLVED.md` item 4 for
what that means for historical (as opposed to current) state.

## CDaoToken — 0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0 (the target)

| Field | Value |
|---|---|
| `owner()` | `0xB9a393eEA994f8c876e4D8d3CDBC6c8c72221eA5` (EOA, 0 BNB-relevant checks not run, holds **0 CDAO**) |
| `governance()` | `0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13` — unchanged from the constructor's hardcoded value; see `GovernanceProxy_...` below |
| `targetPool()` | `0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df` (the CDAO/ProToken PancakePair) |
| `transferStatus()` | `false` — **transfers out of the pool are currently disabled** (buys revert unless the recipient is whitelisted or the DEAD address) |
| `sellRatio()` | `2800` / 10000 = **28% sell tax**, burned to `0x...dEaD` on every sale to the pool |
| `targetRatio()` | `200` / 10000 = 2% (used by `balancePool()`) |
| `lastBalanceTime()` | `0` — `balancePool()` has never been called |
| `cooldownTime()` | `3600` (1 hour) |
| `totalSupply()` | 180,000,000 CDAO (9 decimals) — fixed, no mint function exists beyond the constructor |
| Balance of `targetPool` (the pair) | 1,520,235.6 CDAO (≈0.84% of supply) |
| Balance of `governance()` (the proxy) | **59,163,212.9 CDAO (32.9% of supply)** |
| Balance of `0x...dEaD` | 39,402,804.4 CDAO (21.9% of supply) |
| Balance of `owner()` | 0 |
| Unaccounted for | ≈79.9M CDAO (44.4%) — held by addresses not identified in this review; see `UNRESOLVED.md` item 4 |
| `GOV.allowance(GOV, ProxyAdmin)` / `GOV.allowance(GOV, Safe)` | both `0` — no standing CDAO approval out of the governance proxy |

## PancakePair (targetPool) — 0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df

| Field | Value |
|---|---|
| `token0()` | `0x8D65744527f55d0b2338350912d5C99A81ddF0e2` (**ProToken**, not BNB/BUSD/USDT) |
| `token1()` | `0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0` (CDaoToken) |
| `factory()` | `0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73` (canonical PancakeSwap V2 factory) |
| reserve0 (ProToken) | 97,935.13 |
| reserve1 (CDaoToken) | 1,520,235.6 |
| LP `totalSupply()` | 0.000382673931980175 (18 decimals) — an extremely thin pool |
| `blockTimestampLast` | 2026-08-17 08:27:22 UTC (actively traded, close to snapshot time) |

CDAO's only market is priced entirely in ProToken, not in BNB or a stablecoin —
its USD value is a function of ProToken's own price two hops away (via
ProToken's separate ProToken/BSC-USD pool, see below). This pool is also
extremely thin (LP supply ~3.8e14 wei of an 18-decimal token — well under a
single whole LP token), meaning CDAO's on-chain "price" is unusually easy to
move with small trades.

## Token / "ProToken" — 0x8D65744527f55d0b2338350912d5C99A81ddF0e2

The other side of CDAO's only pool. Structurally near-identical source to
CDaoToken (same whitelist/sell-tax/target-pool pattern) but a distinct
deployment with its own state.

| Field | Value |
|---|---|
| `owner()` | `0x000000000000000000000000000000000000dEaD` — **ownership renounced** (Gnosis Safe tx nonce 10, 2026-05-01) |
| `governance()` | `0x96079eF9b7630A55608a3d4b90733AC56434a5fF` (its own separate `TransparentUpgradeableProxy`; implementation unverified — `UNRESOLVED.md` item 3) |
| `treasury()` | `0xf9074b5C035c961443373F78A6344e5Adc61d314` (the CryptoTreasury proxy — this is what's authorized to `mint()` ProToken) |
| `targetPool()` | `0x63844bd4bfad910b1643713302a1cc1ed20d50c3` — **a different pair than the CDAO/ProToken pool**: this is ProToken/BSC-USD. ProToken's own sell-tax/transfer-restriction logic (`_update`) only applies against *this* pool, so trading ProToken against CDAO on the CDAO pair is **not** subject to ProToken's own tax/whitelist rules — only CDaoToken's rules apply on that venue. |
| `transferStatus()` | `true` — buys from ProToken's own pool are currently enabled |
| `sellRatio()` | `250` / 10000 = 2.5% |
| `targetRatio()` | `500` / 10000 = 5% (the contract-enforced max) |
| `feeReceiver()` | `0x543302E9D9411E563Ad8266CeeF2A85B66050832` |
| `totalSupply()` | 10,805,565.6 ProToken |

## GovernanceProxy — 0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13 (CDaoToken's `governance`)

Verified `TransparentUpgradeableProxy` (OpenZeppelin v5.5.0, byte-identical to
upstream). ProxyAdmin: `0xd290bd0810f075e0b6128e9d3a08948dfc985b66`, owned by the
Gnosis Safe. Etherscan records its current implementation as `RBSControl`
(0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888) and live `eth_call` probing agrees
(see `UNRESOLVED.md` item 1 for the storage-slot discrepancy this review could
not fully explain). As delegate-executed right now:

| RBSControl field (read through the proxy) | Value |
|---|---|
| `owner()` | `0xe561346babe61050f04b6756c303c1c9777e4a59` (hot EOA, 6,088 txs, 0.042 BNB — **not** one of the Safe's 32 signers) |
| `treasury()` | `0xf9074b5C035c961443373F78A6344e5Adc61d314` |
| `usd()` | `0x55d398326f99059fF775485246999027B3197955` (BSC-USD / Binance-Peg USDT) |
| `pair()` | `0x63844bd4bfad910b1643713302a1cc1ed20d50c3` (ProToken/BSC-USD — **not** the CDAO pool) |
| `swapRouter()` | `0x10ED43C718714eb63d5aA57B78B54704E256024E` (canonical PancakeSwap Router02) |
| `lastMintTimes()` | 2026-07-07 11:12:12 UTC |

**This proxy's currently-active configuration has nothing to do with CDAO's own
pool** — it's wired for ProToken's USD-denominated treasury operations. CDAO's
`onlyGovernance` functions (`setTargetRatio`, `balancePool`) cannot presently be
triggered by anyone, because RBSControl contains no code path that calls back
into CDaoToken. The 59.16M CDAO parked at this address is a passive balance,
not something CDAO-specific governance logic is actively using.

## ProxyAdmin — 0xd290bd0810f075e0b6128e9d3a08948dfc985b66

`owner()` → the Gnosis Safe (`0x912008f7f56650bFcBa8102cdCD8ABD889769997`). Not
verified on the block explorer itself, but its sibling `TransparentUpgradeableProxy`
deployments (this same bundle is reused for all proxies in this graph) include
OpenZeppelin v5.5.0's `ProxyAdmin.sol` verbatim as a dependency, and this
contract's bytecode/behavior (Ownable-gated `upgradeAndCall(proxy,implementation,data)`,
selector `0x9623609d`, matches exactly) is consistent with an unverified stock
deployment of that same file. Treat as "very likely stock OZ ProxyAdmin,
unverified" rather than confirmed by source match.

## Gnosis Safe — 0x912008f7f56650bFcBa8102cdCD8ABD889769997

Real, actively-used Safe (v1.4.1+L2), confirmed via Safe's own transaction
service API (`safe-transaction-bsc.safe.global`):

- **Threshold: 19 of 32 owners.**
- 21 executed transactions (nonce 0–20), spanning 2026-03-11 → 2026-08-09.
- Owns the ProxyAdmin above, and at least one other ProxyAdmin-style admin
  relationship implied by its tx history (calls into `0x9641d764fc13c8B624c04430C7356C1C7C8102e2`,
  the canonical Gnosis `MultiSendCallOnly` contract, used for batched owner/
  threshold management early on).
- Full owner list is in `GnosisSafe19of32_.../NOTES.md`.
- Transferred ownership of ProToken (nonce 10) and of at least the Treasury
  proxy and `0xC0021e0849faDefB98761f40829009905Dbd8Ee8` (nonces 6/9/14/15) to
  a single signer EOA, `0x7d38AB50190106e77F382F360268Ea2Ac233C623` — see
  `UNRESOLVED.md` item 2 for why "ownership transferred" and "current owner()"
  don't agree for that contract.

## Treasury proxy — 0xf9074b5C035c961443373F78A6344e5Adc61d314

Verified `TransparentUpgradeableProxy`, implementation `CryptoTreasury`
(0xE6fa68BA6c32F2C18C52380277B563C89847B901). `owner()` reads as the Safe
directly (unlike the CDAO governance proxy, which delegates to a separate hot
EOA). This is an Olympus-style reserve treasury: it holds **mint authority over
ProToken** (`IProToken(proToken).mint()`, gated to addresses the Safe has
`queue()`d + `toggle()`d as `RESERVEDEPOSITOR`/`REWARDMANAGER`, with only a
**1-block queue delay** — `blocksNeededForQueue = 1`, effectively no timelock).
`rbs` (the address permitted to call `depositStableReserve`) is settable by the
Safe via `setRbsContract`.

## CryptoTreasury (0xE6fa68BA6c32F2C18C52380277B563C89847B901) — implementation for the above

Source in `CryptoTreasury_0xE6fa68BA.../`. Key point for this audit: it is the
mechanism by which new ProToken supply gets created, and ProToken is CDAO's only
liquidity counterparty — so ProToken supply/price manipulation via this Treasury
propagates directly into CDAO's own pool pricing.

## CryptoTreasury role holders (live) — the ProToken mint authorities

Read live from the treasury's role arrays (2026-08-17). **All are proxies backed by
unverified Olympus-fork implementations** — see `SECURITY_AUDIT.md` Finding B and
the `bsc/Olympus*` folders.

| Role | Holder proxies | Impl (unverified) | What the role can do |
|---|---|---|---|
| `rbs` | `0xc2D8595…` (RBSControl proxy) | RBSControl (verified) | call `depositStableReserve` |
| `reserveDepositor` | `0xd337…`, `0xC56D…`, `0xaa04…` | `0x03a05f1b…` reserve BondDepository | `depositStableReserve`, `depositBondReserve`(no), `destroyBondReserve` (unbounded `_profit` mint — Finding A) |
| `liquidityDepositor` | `0x941D…`, `0x59dF…`, `0x7365…`, `0x510E…` | `0xa394dcc7…` LP BondDepository | `depositBondReserve` (mint against bonded LP) |
| `rewardManager` + `reserveManager` | `0x7B09…` | `0x62e52600…` StakingDistributor | `mintRewards` (≤ `excessReserves()`) |

Other live treasury config: `rbs = 0xc2D8595…`; `proToken = 0x8D657445…`;
`usd = 0x55d398326f…` (BSC-USD); `reserveTokens = [BSC-USD, ProToken]`;
`liquidityTokens = [0x63844bd4…]` (ProToken/BSC-USD LP); `dead = 0x…dEaD`;
**`blocksNeededForQueue = 1`** (effectively no timelock on role grants — Finding C);
`totalReserves ≈ 1.16e16` (raw). Bond terms across the depositories are set by EOA
`0x8533e14Caea7C622A1Dc69B9eb5f0e47b79CE6A7`.
