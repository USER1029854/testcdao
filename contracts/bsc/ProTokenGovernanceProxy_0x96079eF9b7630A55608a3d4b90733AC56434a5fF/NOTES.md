# ProToken governance proxy — 0x96079eF9b7630A55608a3d4b90733AC56434a5fF

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: `ProToken.governance()` — ProToken's own equivalent of CDAO's
  `GovernanceProxy_0xc2D8595.../`, one hop from CDAO via the shared pool
  (CDAO's only pool is CDAO/ProToken; ProToken's own governance authority is
  therefore part of CDAO's extended trust graph even though nothing in either
  token's code names the other).
- **Verified (proxy shell only)**: Yes — `TransparentUpgradeableProxy`,
  OpenZeppelin v5.5.0 (same source as `GovernanceProxy_0xc2D8595.../`, not
  duplicated here).
- **Proxy**: Yes. Current implementation per Etherscan:
  `0xfdbf6f706e3f01a5152c1c0d2be337e03dd36229` — **not verified**. Not
  decompiled in this review due to time; see `../../UNRESOLVED.md` item 3.
- Live probing: `owner()` read through this proxy resolves to
  `0x7d38AB50190106e77F382F360268Ea2Ac233C623` — a Gnosis Safe signer (see
  `GnosisSafe19of32_.../NOTES.md`), the same address the Safe designated as
  `owner`/recipient for several other contracts in this graph. Other
  RBSControl-style accessors (`treasury()`, `usd()`, `pair()`, `swapRouter()`)
  were not successfully probed (public RPC rate limits during this review) —
  recommended as a quick, cheap follow-up for the audit.
