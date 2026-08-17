# PancakePair — 0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Address**: `0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df`
- **Contract name (as verified)**: `PancakePair`
- **User label**: "pair"
- **Verified**: Yes — full Solidity source retrieved from the block explorer (Etherscan V2 API, `chainid=56`).
- **Proxy**: No. The explorer's proxy detection flag is `0` (not a proxy), and the fetched source is a complete, self-contained PancakeSwap V2 pair implementation (AMM pool logic, LP token accounting, `mint`/`burn`/`swap`), not a thin delegatecall stub. There is no separate implementation contract to resolve.
- **Compiler**: `v0.5.16+commit.9c3226ce`, optimization disabled, 200 runs, EVM version: default
- **License**: MIT

## Source layout

Source was returned in "flattened" form (single file with `// File: <path>` markers) and has been split back out into its original file tree under `source/`:

```
source/
├── contracts/
│   ├── PancakeERC20.sol
│   ├── PancakePair.sol
│   ├── interfaces/
│   │   ├── IERC20.sol
│   │   ├── IPancakeCallee.sol
│   │   ├── IPancakeERC20.sol
│   │   ├── IPancakeFactory.sol
│   │   └── IPancakePair.sol
│   └── libraries/
│       ├── Math.sol
│       ├── SafeMath.sol
│       └── UQ112x112.sol
```

`abi.json` in this folder is the verified ABI as returned by the explorer.

This is the standard, unmodified PancakeSwap V2 `PancakePair` contract deployed at this address.

## Integrity check

The first GitHub reference tried (`pancakeswap/pancake-swap-core` @ `master`)
turned out to encode a *different* fee formula (0.2%-style constants) than
what's actually deployed on-chain — comparing against a stale/wrong branch
would have produced a false "tampered" finding. Re-verified instead against
the **first pair PancakeSwap's own factory ever created**
(`factory().allPairs(0)`, a definitionally-genuine on-chain reference,
independent of any GitHub repo state) — full byte-for-byte match (modulo
line endings, blank lines, and import statements stripped by Etherscan's
flattened-source format) across `PancakePair.sol`, `PancakeERC20.sol`, and all
interfaces/libraries. **No modifications found.**

## Composition — not a BNB/stablecoin pair

`token0()` = `0x8D65744527f55d0b2338350912d5C99A81ddF0e2` (**ProToken**, see
`../Token_0x8D65744527f55d0b2338350912d5C99A81ddF0e2/`), `token1()` = CDaoToken.
This is CDAO's **only** liquidity pool, and it is priced entirely in ProToken,
not BNB or a stablecoin — CDAO's USD value is a function of ProToken's own
price on a separate pool two hops away. Live reserves, LP supply, and
last-trade timestamp are recorded in `../../AUTHORITY_AND_CONFIG.md`; the LP
pool is extremely thin.
