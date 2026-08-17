# CDAO token — audit-ready trust-graph archive

Target: `CDaoToken`, `0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0`, BNB Smart
Chain (chain ID 56).

This repo exists so an auditor can reason about the target's security without
going back to a block explorer: it contains real source (or, where
unavailable, recovered/empirically-determined behavior) for the target and
every contract that bears on its security in either direction, plus a live
snapshot of on-chain authority and configuration state that the source code
alone cannot show. Read `AUTHORITY_AND_CONFIG.md` and `UNRESOLVED.md` first —
they're the parts a source dump can't replace.

## The graph, in one picture

```
                    ┌─────────────────────────────────────────────┐
                    │        Gnosis Safe (19-of-32 threshold)      │
                    │  0x912008f7f56650bFcBa8102cdCD8ABD889769997  │
                    └───────────────┬───────────────────────────┬─┘
                                    │ owner()                    │ owner() (via proxy)
                                    ▼                             ▼
                    ┌───────────────────────────┐   ┌─────────────────────────────┐
                    │  ProxyAdmin (unverified)   │   │ 0xC0021e0849...9905Dbd8Ee8   │
                    │ 0xd290bd0810...dfc985b66   │   │  (role unknown — UNRESOLVED) │
                    └──────┬─────────────┬───────┘   └──────────────┬───────────────┘
             upgradeAndCall│             │upgradeAndCall            │ impl (unverified)
                            ▼             ▼                          ▼
        ┌──────────────────────┐  ┌────────────────────┐  ┌─────────────────────────┐
        │ GovernanceProxy       │  │ TreasuryProxy       │  │ 0x6d694ce9...df2f54      │
        │ 0xc2D8595...4dF09A13  │  │ 0xf9074b5C...61d314 │  │  (UNRESOLVED)            │
        │ = CDaoToken.governance│  │ = ProToken.treasury  │  └──────────────────────────┘
        │ impl → RBSControl     │  │ impl → CryptoTreasury│
        │ holds 32.9% of CDAO   │  │ mints ProToken       │
        │ supply, currently     │  └──────────┬───────────┘
        │ owned (day-to-day) by │             │ mint()
        │ hot EOA 0xe561...4a59 │             ▼
        └───────────┬────────────┘   ┌──────────────────────┐
                    │ (no code path  │  ProToken               │
                    │  back to CDAO  │  0x8D65744527...81ddF0e2│
                    │  right now)    │  owner: renounced→dEaD  │
                    │                │  own governance proxy:  │
                    │                │  0x96079eF9...56434a5fF │
                    │                │  (impl unverified)      │
                    │                └──────────┬───────────────┘
                    │                            │ token0 of
                    │                            ▼
                    │                ┌─────────────────────────────┐
                    └───────────────▶│ PancakePair (CDAO's ONLY pool)│
        59.16M CDAO parked here      │ 0x86aC451a...9E9c630df        │
        (holds this ERC-20 balance,  │ token0=ProToken token1=CDAO   │
        not wired into CDAO logic)   └─────────────────────────────┘
                                                    ▲
                                                    │ token1 of
                                     ┌──────────────┴───────────────┐
                                     │        CDaoToken (TARGET)     │
                                     │ 0xa9d33E92...0C5d7cD0          │
                                     │ owner: 0xB9a393eE...c72221eA5  │
                                     │ (EOA, ordinary Ownable control)│
                                     └────────────────────────────────┘
```

## How to read this

**Downstream from the target** (what CDaoToken leans on): its only liquidity
pool (`PancakePair_0x86aC451a.../`), which is paired against ProToken, not
BNB/BUSD/USDT — so read `Token_0x8D65744527f55d0b2338350912d5C99A81ddF0e2/`
too, since it's the other half of CDAO's market. That's the entire downstream
graph; CDaoToken itself has no other external calls beyond `IPancakePair.sync()`
on its own pool.

**Upstream from the target** (what has power over it, found by walking
outward from `governance`/`owner`, not by reading CDaoToken's source — nothing
below this point is named anywhere in CDaoToken's own code):
`GovernanceProxy_0xc2D8595.../` → `ProxyAdmin_0xd290bd0810.../` →
`GnosisSafe19of32_0x912008f7.../`, plus everything that Safe also controls
(`TreasuryProxy_0xf9074b5C.../`, `CryptoTreasury_0xE6fa68BA.../`,
`RBSControl_0xD50Eda29.../`, and the two still-unresolved proxies
`UnnamedTreasuryProxy_0xC0021e08.../` and
`ProTokenGovernanceProxy_0x96079eF9.../`) — because that Safe's authority
extends through ProToken (CDAO's pool counterparty) back into CDAO's own
economics.

## Folder index

| Folder | Address | Verified | Role |
|---|---|---|---|
| [`bsc/CDaoToken_0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0`](bsc/CDaoToken_0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0) | `0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0` | Yes | **Target.** ERC-20, owner-gated whitelist/sell-tax/pool-transfer-restriction token. |
| [`bsc/PancakePair_0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df`](bsc/PancakePair_0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df) | `0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df` | Yes | `targetPool` — CDAO's only liquidity pool (CDAO/ProToken). Confirmed unmodified PancakeSwap V2. |
| [`bsc/Token_0x8D65744527f55d0b2338350912d5C99A81ddF0e2`](bsc/Token_0x8D65744527f55d0b2338350912d5C99A81ddF0e2) | `0x8D65744527f55d0b2338350912d5C99A81ddF0e2` | Yes | "ProToken" — CDAO's sole pool counterparty; structurally near-identical to CDaoToken but a separate deployment with mint authority. |
| [`bsc/GovernanceProxy_0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13`](bsc/GovernanceProxy_0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13) | `0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13` | Yes | `CDaoToken.governance()`. Upgradeable proxy; holds 32.9% of CDAO supply. |
| [`bsc/RBSControl_0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888`](bsc/RBSControl_0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888) | `0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888` | Yes | Implementation currently behind the governance proxy above. AMM/treasury ops helper. |
| [`bsc/ProxyAdmin_0xd290bd0810f075e0b6128e9d3a08948dfc985b66`](bsc/ProxyAdmin_0xd290bd0810f075e0b6128e9d3a08948dfc985b66) | `0xd290bd0810f075e0b6128e9d3a08948dfc985b66` | **No** | Admin of the governance proxy and the treasury proxy. Recovered behavior only. |
| [`bsc/GnosisSafe19of32_0x912008f7f56650bFcBa8102cdCD8ABD889769997`](bsc/GnosisSafe19of32_0x912008f7f56650bFcBa8102cdCD8ABD889769997) | `0x912008f7f56650bFcBa8102cdCD8ABD889769997` | Standard | Owner of the ProxyAdmin above — the top of this authority chain. 19-of-32 multisig. |
| [`bsc/TreasuryProxy_0xf9074b5C035c961443373F78A6344e5Adc61d314`](bsc/TreasuryProxy_0xf9074b5C035c961443373F78A6344e5Adc61d314) | `0xf9074b5C035c961443373F78A6344e5Adc61d314` | Yes | `ProToken.treasury()`. Upgradeable proxy administered by the same Safe. |
| [`bsc/CryptoTreasury_0xE6fa68BA6c32F2C18C52380277B563C89847B901`](bsc/CryptoTreasury_0xE6fa68BA6c32F2C18C52380277B563C89847B901) | `0xE6fa68BA6c32F2C18C52380277B563C89847B901` | Yes | Implementation behind the treasury proxy. Holds mint authority over ProToken. |
| [`bsc/UnnamedTreasuryProxy_0xC0021e0849faDefB98761f40829009905Dbd8Ee8`](bsc/UnnamedTreasuryProxy_0xC0021e0849faDefB98761f40829009905Dbd8Ee8) | `0xC0021e0849faDefB98761f40829009905Dbd8Ee8` | Shell only | Same admin family, role unresolved. **See `UNRESOLVED.md`.** |
| [`bsc/ProTokenGovernanceProxy_0x96079eF9b7630A55608a3d4b90733AC56434a5fF`](bsc/ProTokenGovernanceProxy_0x96079eF9b7630A55608a3d4b90733AC56434a5fF) | `0x96079eF9b7630A55608a3d4b90733AC56434a5fF` | Shell only | `ProToken.governance()`. Implementation unresolved. **See `UNRESOLVED.md`.** |
| [`bsc/OlympusReserveBondDepository_0x03a05f1b78c075fd506d2ec38b5020cf571d5ace`](bsc/OlympusReserveBondDepository_0x03a05f1b78c075fd506d2ec38b5020cf571d5ace) | `0x03a05f1b…` | **No** (recovered) | Reserve BondDepository impl behind the 3 `reserveDepositor` proxies. Holds ProToken mint authority. **Value-path, unverified — see `SECURITY_AUDIT.md` B.** |
| [`bsc/OlympusLPBondDepository_0xa394dcc7433809b313948616a768591324318364`](bsc/OlympusLPBondDepository_0xa394dcc7433809b313948616a768591324318364) | `0xa394dcc7…` | **No** (recovered) | LP BondDepository impl behind the 4 `liquidityDepositor` proxies. Permissionless `deposit()`. **Value-path, unverified — see `SECURITY_AUDIT.md` B.** |
| [`bsc/OlympusStakingDistributor_0x62e52600d544deb350cf5564e6f1abb67213bec3`](bsc/OlympusStakingDistributor_0x62e52600d544deb350cf5564e6f1abb67213bec3) | `0x62e52600…` | **No** (recovered) | StakingDistributor impl behind the `rewardManager` proxy (`mintRewards`). **Value-path, unverified.** |

## Also see

- **[`SECURITY_AUDIT.md`](SECURITY_AUDIT.md)** — the security review: full
  entry-point enumeration, state-dependency/composition map, findings, and the
  decisive unverified-bonding boundary. Read the Verdict first.
- **[`AUTHORITY_AND_CONFIG.md`](AUTHORITY_AND_CONFIG.md)** — live on-chain
  state (who holds what role right now, balances, pool composition, config
  parameters) as of the 2026-08-17 snapshot. Source code shows what's
  *possible*; this file shows what's *true right now*.
- **[`UNRESOLVED.md`](UNRESOLVED.md)** — everything this review could not
  fully pin down, with the specific open question and whatever evidence
  bounds it for each item. Read this before treating any absence in this repo
  as "nothing there."

## Not deep-dived (well-known, canonical infrastructure)

These addresses appear in the graph (referenced by `RBSControl`/`CryptoTreasury`/
the pools above) but are extremely well-known, canonical BSC infrastructure —
not bespoke to this project — so they were characterized by address/role only
rather than given their own source folder:

- PancakeSwap V2 Factory — `0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73`
- PancakeSwap V2 Router02 — `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- BSC-USD / Binance-Peg USDT — `0x55d398326f99059fF775485246999027B3197955`
- ProToken/BSC-USD PancakePair (RBSControl's configured `pair()`, distinct
  from CDAO's own pool) — `0x63844bd4bfad910b1643713302a1cc1ed20d50c3`
