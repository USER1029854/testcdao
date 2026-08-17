# RBSControl — 0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: the logic contract that `GovernanceProxy_0xc2D8595.../` currently
  delegate-executes as CDaoToken's `governance()` address (see
  `../../UNRESOLVED.md` item 1 for a caveat on how firmly "currently" is
  established). An AMM/treasury operations helper: swap, add/remove liquidity,
  burn LP tokens, and trigger treasury minting, all gated `onlyOwner`.
- **Verified**: Yes. Compiler `v0.8.30+commit.73712a01`, OpenZeppelin
  Contracts-Upgradeable (`OwnableUpgradeable`, `Initializable`).
- **Proxy**: No (this is the implementation; it is reached via delegatecall
  through `GovernanceProxy_0xc2D8595.../`, not deployed as a proxy itself).

## What it does

`initialize(_owner, _router, _pool, _treasury, _usd)` sets an `OwnableUpgradeable`
owner and four config addresses. Once initialized, `owner()` can call:

- `swap(path, amountIn, amountOutMin, deadline)` — swaps the contract's own
  balance of `path[0]` via `swapRouter`, proceeds returned to `address(this)`.
  Cannot send funds to an arbitrary external address by itself.
- `addLiquidity` / `removeLiquidity` — via `swapRouter`, again `to = address(this)`.
- `burnLP()` / `burnCPLP(pair)` — sends the contract's LP balance to `0x...dEaD`.
- `mint(usdAmount, profitAmount)` — pulls up to 200,000 USD-equivalent from the
  contract's own `usd` balance, approves `treasury`, and calls
  `ITreasury(treasury).depositStableReserve(usd, usdAmount, profit)`, which
  (per `CryptoTreasury_.../source/src/Treasury.sol`) mints new ProToken back to
  this contract. Rate-limited to once per 30 minutes. Hardcodes a check against
  ProToken's own address (`0x8D65744527f55d0b2338350912d5C99A81ddF0e2`,
  balance must stay under 20,000 ProToken here) as a guard — direct evidence
  this contract is bespoke to this operator's ProToken/CDAO ecosystem, not a
  generic reused library.

**No function in this contract can move an arbitrary ERC-20 balance (including
the 59.16M CDAO parked at the proxy address) to an address outside itself** —
the worst its current `owner()` can do with CDAO specifically is `swap()` it
via the router, with proceeds still landing back at the proxy. The Safe (via
the ProxyAdmin) retains the power to replace this implementation with
something that can transfer out directly.

## Source layout

```
source/
├── src/RBS.sol                                                 (main contract, `contract RBSControl`)
└── lib/
    ├── openzeppelin-contracts-upgradeable/contracts/
    │   ├── access/OwnableUpgradeable.sol
    │   ├── utils/ContextUpgradeable.sol
    │   └── proxy/utils/Initializable.sol
    └── openzeppelin-contracts/contracts/
        ├── token/ERC20/{IERC20,utils/SafeERC20}.sol
        ├── interfaces/{IERC1363,IERC20,IERC165}.sol
        └── utils/introspection/IERC165.sol
```

`abi.json` in this folder is the verified ABI as returned by the explorer.
