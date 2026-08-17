# GovernanceProxy — 0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: this is `CDaoToken.governance()` — the address whose `onlyGovernance`
  functions (`setTargetRatio`, `balancePool`) on the target token require
  `msg.sender == governance`. **Not found by reading CDaoToken alone** beyond
  the bare address; everything below was found by treating that address as a
  graph node in its own right, exactly the "upstream" direction the brief asks
  for.
- **Verified**: Yes — `TransparentUpgradeableProxy`, OpenZeppelin Contracts
  v5.5.0, compiler `v0.8.30+commit.73712a01`. Source is byte-identical to
  upstream OZ (not independently re-diffed here since it's the reference
  implementation itself, but it matches the file list and header comments of
  the real library).
- **Proxy**: Yes. `ProxyAdmin`: `0xd290bd0810f075e0b6128e9d3a08948dfc985b66`
  (see sibling folder `ProxyAdmin_0xd290bd0810f075e0b6128e9d3a08948dfc985b66/`).
  Etherscan's own proxy detection records current implementation as
  `RBSControl` at `0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888` (see sibling
  folder `RBSControl_0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888/`), matching
  what live `eth_call` probing against this address returns.

## Important caveat

Direct `eth_getStorageAt` reads of the standard EIP-1967 implementation slot
on this address return `0x0`, both now and immediately after the transaction
that emitted the `Upgraded(RBSControl)` event — checked across 6 independent
RPC providers. Live behavioral probing (calling `owner()`, `treasury()`,
`usd()`, `pair()`, `swapRouter()`, `lastMintTimes()`) is fully consistent with
RBSControl actually being the live delegate target. This repo could not fully
reconcile the two observations — see `../../UNRESOLVED.md` item 1. Treat
"RBSControl is currently active here" as strongly evidenced but not proven by
storage inspection alone.

## What it currently does (via RBSControl, live-probed)

This proxy's currently-active configuration is wired for **ProToken's own
USD-denominated treasury operations** (`pair()` = ProToken/BSC-USD, `usd()` =
BSC-USD, `treasury()` = the CryptoTreasury proxy), not for CDAO's pool. Its
`owner()` (the address allowed to call RBSControl's `swap`/`addLiquidity`/
`removeLiquidity`/`burnLP`/`mint`) is `0xe561346babe61050f04b6756c303c1c9777e4a59`,
an actively-used (6,088 tx) hot EOA that is **not** one of the Gnosis Safe's 32
signers.

Because RBSControl has no code path that calls into CDaoToken, **CDaoToken's
own `onlyGovernance` functions currently cannot be triggered by anyone** —
this proxy can't act as CDAO's governance in practice right now, only in name.
It is, however, sitting on **59,163,212.9 CDAO (32.9% of total supply)** as a
passive ERC-20 balance, with zero standing approvals granted out. RBSControl's
public interface has no raw transfer/withdraw function, so the current
`owner()` cannot move that balance out directly — but the Gnosis Safe, via the
ProxyAdmin, can replace the implementation with anything at will, including
logic that would.

## Source layout

```
source/
├── src/RBS.sol                                    (NOT here — this is the PROXY; RBSControl lives in its own folder)
└── lib/openzeppelin-contracts/contracts/
    ├── proxy/transparent/TransparentUpgradeableProxy.sol
    ├── proxy/transparent/ProxyAdmin.sol
    ├── proxy/ERC1967/ERC1967Proxy.sol
    ├── proxy/ERC1967/ERC1967Utils.sol
    ├── proxy/Proxy.sol
    ├── proxy/beacon/IBeacon.sol
    ├── interfaces/IERC1967.sol
    ├── access/Ownable.sol
    ├── utils/{Address,StorageSlot,Errors,LowLevelCall,Context}.sol
```

`abi.json` in this folder is the verified ABI as returned by the explorer.
