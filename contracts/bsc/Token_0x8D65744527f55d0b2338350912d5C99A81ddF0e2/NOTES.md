# Token — 0x8D65744527f55d0b2338350912d5C99A81ddF0e2

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Address**: `0x8D65744527f55d0b2338350912d5C99A81ddF0e2`
- **Contract name (as verified)**: `Token`
- **User label**: "pro"
- **Verified**: Yes — full Solidity source retrieved from the block explorer (Etherscan V2 API, `chainid=56`).
- **Proxy**: No. The explorer's proxy detection flag is `0` (not a proxy). The fetched source is a standard OpenZeppelin-based `ERC20`/`Ownable` token with its own custom logic (governance/treasury roles, whitelist, sell-tax, liquidity-pool transfer restrictions and auto-balancing — see `source/src/ProToken.sol`), not a delegatecall stub. There is no separate implementation contract to resolve.
- **Compiler**: `v0.8.30+commit.73712a01`, optimization enabled, 200 runs, EVM version: cancun
- **License**: MIT (per `// SPDX-License-Identifier: MIT` in the main source file; the explorer's `LicenseType` field was left blank on this submission)

## Source layout

Source was returned as a Standard-JSON-Input multi-file bundle and has been written out to its original file tree under `source/`:

```
source/
├── src/
│   └── ProToken.sol                                            (main contract, named `Token`)
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

Note: the main contract file is named `ProToken.sol` on disk (as submitted for verification) but declares `contract Token`. This contract is structurally very similar to `CDaoToken` (0xa9d33E9203E7d4B9EA8f37Eca73CFe810C5d7cD0) — same governance/whitelist/sell-tax pattern — but is a distinct deployment with its own address, roles, and state.
