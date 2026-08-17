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
