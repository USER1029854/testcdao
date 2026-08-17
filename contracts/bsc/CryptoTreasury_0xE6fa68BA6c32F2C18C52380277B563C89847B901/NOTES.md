# CryptoTreasury — 0xE6fa68BA6c32F2C18C52380277B563C89847B901

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: implementation behind `TreasuryProxy_0xf9074b5C.../` — an
  Olympus-DAO-style reserve treasury holding **mint authority over ProToken**
  (`0x8D65744527f55d0b2338350912d5C99A81ddF0e2`), the token paired with CDAO in
  its only liquidity pool. Reached two hops upstream from CDAO
  (CDAO pool → ProToken → ProToken.treasury() → this contract's mint power),
  entirely invisible from reading CDaoToken's own source.
- **Verified**: Yes. Compiler `v0.8.30+commit.73712a01`,
  `OwnableUpgradeable`/`Initializable`.
- **Proxy**: No (implementation only).

## What it does

Classic queue/toggle reserve-management pattern: the `owner()` (the Gnosis
Safe, `0x912008f7f56650bFcBa8102cdCD8ABD889769997`) can `queue()` an address
against one of 8 `MANAGING` roles (reserve depositor/spender/token/manager,
liquidity depositor/token/manager, reward manager), then `toggle()` it live
after a **`blocksNeededForQueue` delay of just 1 block** (set in `initialize`,
never changed as far as this review could tell) — a nominal timelock with no
real protective effect. Addresses granted `RESERVEDEPOSITOR` or authorized via
`setRbsContract(rbs)` can call `depositStableReserve`, which pulls in a
reserve token (BSC-USD) and **mints fresh ProToken** via
`IProToken(proToken).mint()`. `mintRewards` similarly mints to any address the
owner has flagged `REWARDMANAGER`.

**Audit-relevant point**: this contract, not ProToken's own code, is where
ProToken's supply-inflation authority actually lives, and it's Safe-controlled
with an effectively-instant queue delay. Since ProToken is CDAO's only pricing
counterparty, minting ProToken here dilutes/moves the CDAO/ProToken exchange
rate without CDAO's own contract being touched at all.

## Source layout

```
source/
├── src/Treasury.sol                                            (main contract, `contract CryptoTreasury`)
└── lib/
    ├── openzeppelin-contracts-upgradeable/contracts/{access/OwnableUpgradeable,utils/ContextUpgradeable,proxy/utils/Initializable}.sol
    └── openzeppelin-contracts/contracts/{token/ERC20/IERC20,token/ERC20/utils/SafeERC20,interfaces/IERC1363,interfaces/IERC20,interfaces/IERC165,utils/introspection/IERC165}.sol
```

`abi.json` in this folder is the verified ABI as returned by the explorer.
