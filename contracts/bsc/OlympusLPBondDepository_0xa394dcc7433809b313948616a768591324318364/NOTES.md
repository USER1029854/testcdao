# Olympus LP BondDepository (impl) — 0xa394dcc7433809b313948616a768591324318364

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: implementation shared by the **4 `liquidityDepositor`** proxies the
  CryptoTreasury (`0xf9074b5C…`) authorizes to mint ProToken against bonded LP:
  `0x941D4DCf45b7dD8D2C635c78FB21E03D55510298`,
  `0x59dF359C2EB7c547e90Ec60426f083D75057675c`,
  `0x7365cfD127167F33Dd0467361cAA7217eA271976`,
  `0x510E840f1Ce72DCB6B296b4C8FcbC0e99560C7a8`.
- **Verified**: **No.** No source on the block explorer for this implementation.
  This is an unverified contract *in the value path* — it holds live authority to
  cause ProToken (CDAO's pool counterparty) to be minted. See
  `../../SECURITY_AUDIT.md` Finding B and `../../UNRESOLVED.md`.

## Recovered behavior (bytecode only)

- `recovered/runtime_bytecode.hex` — full runtime bytecode (15,090 bytes) as
  returned by `eth_getCode`.
- `recovered/push4_selectors.txt` — the 100 `PUSH4` constants in the dispatcher.
- Resolved selectors identify this as a **canonical Olympus DAO V1 LP
  BondDepository**: `deposit(uint256,uint256,address)` (`0x8dbdbe6d`),
  `redeem(address,uint256,bool)` (`0x4458a14c`), `getBondPrice(uint256)`,
  `bondPriceInUSD` , `maxPayout`, `debtRatio`, `standardizedDebtRatio`, `totalDebt`,
  `debtDecay`, `lastDecay`, `isLiquidityBond`, `bondCalculator`, `setBondTerms`,
  `setAdjustment`, `stake`/`stakingHelper`, OZ v5 `Ownable`
  (`OwnableUnauthorizedAccount` custom error `0x118cdaa7` present).
- **Empirical reachability**: `deposit(1, type(uint256).max, <random addr>)` called
  from an arbitrary unprivileged `from` reverts with fork-specific custom error
  `0x5e23f093` — i.e. it passes the owner gate and reverts inside deposit logic.
  **The bond `deposit` path is permissionless.**
- **Admin** (sets bond terms/price): EOA
  `0x8533e14Caea7C622A1Dc69B9eb5f0e47b79CE6A7` (via each proxy's `owner()`).

## Why this matters / what remains open

An unprivileged user can bond LP and receive newly-minted ProToken at a price this
contract computes off pool reserves (`bondCalculator` valuation) — reserves a
flash-loan-funded attacker can move. Whether the payout can exceed deposited value
is unverifiable from bytecode and is the load-bearing open question for the whole
system's solvency (`SECURITY_AUDIT.md` Finding B). To close: obtain/decompile source
and audit the Olympus bond math + LP valuation against reserve manipulation.
