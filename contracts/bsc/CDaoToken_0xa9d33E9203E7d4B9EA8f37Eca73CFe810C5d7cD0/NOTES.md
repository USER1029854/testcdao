# CDaoToken — 0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Address**: `0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0`
- **Contract name (as verified)**: `CDaoToken`
- **User label**: "token"
- **Verified**: Yes — full Solidity source retrieved from the block explorer (Etherscan V2 API, `chainid=56`).
- **Proxy**: No. The explorer's proxy detection flag is `0` (not a proxy). The fetched source is a standard OpenZeppelin-based `ERC20`/`Ownable` token with its own custom logic (whitelist, target-pool/ratio, sell-ratio, cooldown, etc. — see `source/src/CToken.sol`), not a delegatecall stub. There is no separate implementation contract to resolve.
- **Compiler**: `v0.8.30+commit.73712a01`, optimization enabled, 200 runs, EVM version: cancun
- **License**: MIT (per `// SPDX-License-Identifier: MIT` in the main source file; the explorer's `LicenseType` field was left blank on this submission)

## Source layout

Source was returned as a Standard-JSON-Input multi-file bundle and has been written out to its original file tree under `source/`:

```
source/
├── src/
│   └── CToken.sol                                              (main contract, named `CDaoToken`)
└── lib/
    └── openzeppelin-contracts/
        └── contracts/
            ├── access/Ownable.sol
            ├── interfaces/draft-IERC6093.sol
            ├── token/ERC20/ERC20.sol
            ├── token/ERC20/IERC20.sol
            ├── token/ERC20/extensions/IERC20Metadata.sol
            └── utils/Context.sol
```

`abi.json` in this folder is the verified ABI as returned by the explorer.

Note: the main contract file is named `CToken.sol` on disk (as submitted for verification) but declares `contract CDaoToken`.

## Library integrity

`Ownable.sol`, `ERC20.sol`, `IERC20.sol`, `IERC20Metadata.sol`, `Context.sol`,
and `draft-IERC6093.sol` under `source/lib/` were diffed byte-for-byte (modulo
line endings) against OpenZeppelin Contracts `v5.5.0` fetched fresh from
`github.com/OpenZeppelin/openzeppelin-contracts` — **identical**, no
modifications found.

## Trust graph — see `../../AUTHORITY_AND_CONFIG.md` and `../../UNRESOLVED.md`

This contract's own code is small and was fully read; almost everything that
actually bears on its security lives outside it:

- `targetPool()` → `PancakePair_0x86aC451a.../` — CDAO's **only** liquidity
  pool, paired against ProToken (`Token_0x8D65744527f55d0b2338350912d5C99A81ddF0e2/`),
  not against BNB or a stablecoin.
- `governance()` → `GovernanceProxy_0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13/`,
  an upgradeable proxy currently holding **32.9% of CDAO's total supply**,
  administered by a 19-of-32 Gnosis Safe
  (`GnosisSafe19of32_0x912008f7f56650bFcBa8102cdCD8ABD889769997/`) via
  `ProxyAdmin_0xd290bd0810f075e0b6128e9d3a08948dfc985b66/`. None of this is
  named anywhere in CDaoToken's own source — it was found only by treating
  `governance` as a graph node and walking outward from it.
- Live state (owner, whitelist-adjacent flags, tax rate, transfer status,
  balances) is recorded in `../../AUTHORITY_AND_CONFIG.md`, not just the
  constructor defaults shown in the source above — several of these have
  drifted from their constructor values (e.g. `sellRatio` is unchanged at
  2800/28%, but `transferStatus` is currently `false`, disabling buys from the
  pool for non-whitelisted addresses).

## Event-history scan attempt (partial failure — see `../../UNRESOLVED.md` item 4)

Etherscan V2's `account`/`logs`/`proxy` API modules reject chain 56 on this
key's tier. A chunked `eth_getLogs` scan (deployment-era + recent windows,
~9,500-block chunks) across `bsc.drpc.org`, `bsc-mainnet.public.blastapi.io`,
and `bsc.publicnode.com` was attempted for `OwnershipTransferred`,
`WhitelistAdded`/`Removed`, `BalancePoolAddressUpdated`,
`TokenTransferStateUpdated`, `SellRateChanged`, `BalanceTargetRateChanged`,
`GovernanceAddressupdated`, and `BalancePoolBurned` — **every chunk failed**
(range caps / rate limits on every provider tried). Current-state values were
obtained via direct `eth_call` instead (see `../../AUTHORITY_AND_CONFIG.md`);
full historical admin-action history is not part of this repo.
