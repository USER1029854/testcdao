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
