# Unnamed proxy — 0xC0021e0849faDefB98761f40829009905Dbd8Ee8

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: unknown — included here because the Gnosis Safe that administers
  CDAO's governance proxy interacts with it directly and repeatedly (Safe tx
  nonces 9, 12, 15, 20), and its `ProxyAdmin` (same one:
  `0xd290bd0810f075e0b6128e9d3a08948dfc985b66`) puts it in the same authority
  family. **This is an explicitly unresolved node — see `../../UNRESOLVED.md`
  item 2.**
- **Verified (proxy shell only)**: Yes — `TransparentUpgradeableProxy`,
  OpenZeppelin v5.5.0 (same source as `GovernanceProxy_0xc2D8595.../`, not
  duplicated here).
- **Proxy**: Yes. `ProxyAdmin`: `0xd290bd0810f075e0b6128e9d3a08948dfc985b66`.
  Current implementation per Etherscan: `0x6d694ce971343626429f87ef05e0cd292e3f2f54`
  — **this implementation is not verified**, and was not decompiled/
  bytecode-analyzed in this review due to time. `owner()` read through the
  proxy currently resolves to the Gnosis Safe itself.
- Safe transaction history against this address:
  - nonce 9 (2026-04-26): un-decoded raw call.
  - nonce 12 (2026-05-24): un-decoded raw call.
  - nonce 15 (2026-06-11): `transferOwnership(0x7d38AB50190106e77F382F360268Ea2Ac233C623)` — **not reflected** in the current `owner()` reading (still the Safe), an unexplained discrepancy of the same shape as the governance-proxy storage mismatch (`UNRESOLVED.md` item 1).
  - nonce 20 (2026-08-09, nine days before this review's snapshot): raw call, selector `0x83d58474`, un-decoded by the Safe UI.

**Open question for the audit**: what does `0x6d694ce971343626429f87ef05e0cd292e3f2f54`
do, and what did the 2026-08-09 call actually change? Recommended next step:
decompile that implementation address and/or pull a full trace
(`debug_traceTransaction`) of Safe tx nonce 20's underlying transaction hash.
