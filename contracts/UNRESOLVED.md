# Unresolved items

Everything in this list is something the audit should look at directly rather than
trust this repo's characterization of. Each entry states what is missing and what
evidence bounds it.

## 1. Storage/behavior mismatch on the CDAO "governance" proxy (0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13)

The proxy is verified as a stock OpenZeppelin v5.5.0 `TransparentUpgradeableProxy`
(source in `bsc/GovernanceProxy_0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13/`). Its
`ProxyAdmin` (0xd290bd0810f075e0b6128e9d3a08948dfc985b66), owned by the 19-of-32
Gnosis Safe (0x912008f7f56650bFcBa8102cdCD8ABD889769997), called `upgradeAndCall`
on 2026-06-30 (tx `0xd87ee9249949600829bd4d94e9c80c49572808b62aa0cd840384c301563f4911`,
block 107263133, status success) naming implementation `RBSControl`
(0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888) and emitting the standard
`Upgraded(address)` event with that address.

- **Reading `eth_getStorageAt(proxy, EIP-1967 implementation slot)` returns `0x0`**
  right now, and also at the block immediately after the upgrade transaction. This
  was cross-checked across 6 independent RPC endpoints, including Binance's own
  `bsc-dataseed{1..4}.binance.org` nodes, all agreeing.
- **Yet `eth_call` probes against the proxy succeed** and return values completely
  consistent with `RBSControl` being live: `owner()` → `0xe561346babe61050f04b6756c303c1c9777e4a59`,
  `treasury()` → the Treasury proxy (0xf9074b5C...), `usd()` → BSC-USD
  (0x55d398326f99059fF775485246999027B3197955), `pair()` → the ProToken/BSC-USD
  pair (0x63844bd4bfad910b1643713302a1cc1ed20d50c3), `swapRouter()` → PancakeSwap
  Router02 (0x10ED43C718714eb63d5aA57B78B54704E256024E), `lastMintTimes()` → a
  2026-07-07 timestamp (i.e. `RBSControl.mint()` has actually been called since
  the June 30 upgrade).

**Open question:** why does the canonical implementation-pointer storage slot read
zero while the proxy is demonstrably delegate-executing `RBSControl` logic? Two
non-exclusive possibilities that were not fully run to ground: (a) some RPC-level
quirk specific to this slot/this proxy across every provider tested (would be
unusual given 6-provider agreement), or (b) a mechanism this review did not
identify. This does not change the practical conclusion (the proxy is live and
running RBSControl), but the audit should not take "proxy is live" purely on this
repo's authority — re-derive it independently, e.g. by tracing the actual
`DELEGATECALL` target with a debug/trace RPC method (`debug_traceCall`), which
was not available on the public endpoints used here.

## 2. Unverified implementation behind 0xC0021e0849faDefB98761f40829009905Dbd8Ee8

This is a verified `TransparentUpgradeableProxy` (same ProxyAdmin/Safe as
everything else in this graph) whose current implementation,
`0x6d694ce971343626429f87ef05e0cd292e3f2f54`, **is not verified on the block
explorer**. `owner()` read through the proxy currently returns the Safe address
itself (0x912008f7f56650bFcBa8102cdCD8ABD889769997). The Safe's own transaction
history shows two direct calls to this proxy (nonce 12, 20) with calldata Safe's
UI could not decode, and one `transferOwnership(0x7d38AB50190106e77F382F360268Ea2Ac233C623)`
call (nonce 15) whose effect is not reflected in the current `owner()` reading —
another instance of the same kind of discrepancy as item 1. **What this contract
actually does, and what nonce 20's raw call (`0x83d58474...`, nonce 20,
2026-08-09, nine days before this review) did, were not determined.** Recover it
via bytecode analysis of `0x6d694ce971343626429f87ef05e0cd292e3f2f54` or a
`debug_traceTransaction` on the relevant Safe execution transactions.

## 3. Unverified implementation behind ProToken's own governance proxy (0x96079eF9b7630A55608a3d4b90733AC56434a5fF)

ProToken (0x8D65744527f55d0b2338350912d5C99A81ddF0e2, CDAO's only pool
counterparty) has its own `governance()` slot pointing at a second
`TransparentUpgradeableProxy`, implementation `0xfdbf6f706e3f01a5152c1c0d2be337e03dd36229`,
**also unverified**. Live probing established only that `owner()` through this
proxy resolves to `0x7d38AB50190106e77F382F360268Ea2Ac233C623` (a Safe signer,
also the recipient of the ownership transfers in item 2 and the Treasury-adjacent
contracts — see `AUTHORITY_AND_CONFIG.md`). Whether this implementation can move
funds, and what interface it exposes, was not determined. Same recovery path as
item 2.

## 4. Exhaustive event-log history was not obtainable

Etherscan's V2 API rejects the `account`, `logs`, and `proxy` (eth_call/eth_getLogs
equivalents) modules for chain 56 (BNB Smart Chain) on this free-tier key
("Free API access is not supported for this chain. Please upgrade your api plan").
Only `module=contract` (`getsourcecode`/`getabi`) worked. Public BSC JSON-RPC
endpoints (publicnode, blastapi, drpc, Binance's own dataseed nodes) all cap
`eth_getLogs` to ~10,000-block windows and rate-limit aggressively; a full scan of
CDaoToken's ~11.47M-block lifetime (every ~9,500-block chunk, twice, once for a
deployment-era window and once for a recent window) was attempted and **every
single chunk failed** (see `contracts/bsc/CDaoToken_.../NOTES.md` for the raw
log). No Blockscout instance was found for BNB Smart Chain mainnet (chain 56 is
absent from Blockscout's own chain directory), so the supplied Blockscout API key
could not be used for this chain either.

**Consequence:** this repo's picture of CDaoToken is built entirely from *current*
on-chain state (`eth_call`/`eth_getStorageAt`, cross-validated across providers),
not from full historical event logs. Specifically unknown: the complete
`WhitelistAdded`/`WhitelistRemoved` history (only the current `whitelist[addr]`
mapping value for specific addresses can be checked, and only for addresses
already known — the mapping cannot be enumerated without logs), whether
`CDaoToken.owner()` changed hands before settling on
`0xB9a393eEA994f8c876e4D8d3CDBC6c8c72221eA5`, and the destination(s) of the ~80M
CDAO (~44% of supply) not accounted for by the owner/governance/dead/pair
balances recorded in `AUTHORITY_AND_CONFIG.md`. An audit with paid Etherscan/BSC
archive-node access should re-run this.

## 5. Off-chain / operational trust, not visible on any single contract

- **The Gnosis Safe's 32 individual signers** are pseudonymous EOAs; nothing
  on-chain establishes who they are or how independent they are from one
  another. The 19-of-32 threshold is real and verifiable (Safe transaction
  service, see `GnosisSafe19of32_.../NOTES.md`), but the audit should treat "is
  this actually 19 independent, trustworthy parties" as an open question this
  repo cannot answer from chain data alone.
- **`0xe561346babe61050f04b6756c303c1c9777e4a59`** (RBSControl's day-to-day
  `owner()` for the proxy that holds 59.16M CDAO, 32.9% of supply) is a hot EOA
  with 6,088 transactions and 0.042 BNB balance — an actively used, single-key
  operational wallet, not multisig-protected. A compromise of this one key does
  not (on RBSControl's current interface) directly drain the 59.16M CDAO to an
  attacker address — RBSControl has no raw transfer/withdraw function reachable
  by its `owner()` — but it does grant `swap`/`addLiquidity`/`removeLiquidity`/
  `burnLP`/`mint` power that could be used to manipulate pools RBSControl is
  wired to. This should be treated as a real, if narrower, single-key risk.
- **Whether the 19-of-32 Safe would actually reuse its ProxyAdmin authority to
  drain the 59.16M CDAO sitting at the "governance" address is a decision, not a
  code fact** — the code permits it (ProxyAdmin.owner() = Safe = can upgrade
  `GovernanceProxy_0xc2D8595...`'s implementation to anything, including a
  contract that simply transfers out its own CDAO balance). No on-chain evidence
  either way was found.
