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

## Why this is in the repo: it's the other side of CDAO's only pool

`ProToken` is **not** a tangential curiosity. CDaoToken's `targetPool`
(`PancakePair_0x86aC451a0c0bcAc5b74116Ae90832e89E9c630df/`) is a CDAO/ProToken
pair — ProToken is CDAO's sole liquidity counterparty. It also has its own
`mint(address,uint256)` function, gated `msg.sender == treasury`, unlike
CDaoToken (which has no mint beyond the constructor). Live state — including
`owner()` (renounced to `0x...dEaD`), `governance()` (a separate upgradeable
proxy), `treasury()` (holds this token's mint authority), and `targetPool()`
(a **different** pool, ProToken/BSC-USD, not the CDAO pair) — is recorded in
`../../AUTHORITY_AND_CONFIG.md`. The full upstream authority graph (treasury
mint power, governance proxy, the Gnosis Safe behind both) is written up
starting from `../../AUTHORITY_AND_CONFIG.md` and the sibling
`TreasuryProxy_0xf9074b5C035c961443373F78A6344e5Adc61d314/`,
`CryptoTreasury_0xE6fa68BA6c32F2C18C52380277B563C89847B901/`, and
`ProTokenGovernanceProxy_0x96079eF9b7630A55608a3d4b90733AC56434a5fF/` folders.

## Library integrity

Same OpenZeppelin v5.5.0 dependency tree as CDaoToken — diffed byte-for-byte
against upstream, **identical**, no modifications found.
