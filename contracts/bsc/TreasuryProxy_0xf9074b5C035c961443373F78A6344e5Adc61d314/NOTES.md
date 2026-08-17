# TreasuryProxy — 0xf9074b5C035c961443373F78A6344e5Adc61d314

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: `ProToken.treasury()` — holds mint authority over ProToken (CDAO's
  only pool counterparty). Reached from ProToken → this proxy → `CryptoTreasury`
  implementation.
- **Verified**: Yes — `TransparentUpgradeableProxy`, OpenZeppelin v5.5.0,
  compiler `v0.8.30+commit.73712a01`. Source is identical to
  `GovernanceProxy_0xc2D8595.../source/` (same OZ bundle) and is not duplicated
  here; see that folder for the full proxy source tree.
- **Proxy**: Yes. `ProxyAdmin`: `0xd290bd0810f075e0b6128e9d3a08948dfc985b66`
  (same admin as CDAO's governance proxy — same Safe controls both). Current
  implementation per Etherscan and live probing: `CryptoTreasury`
  (`0xE6fa68BA6c32F2C18C52380277B563C89847B901`, see
  `../CryptoTreasury_0xE6fa68BA6c32F2C18C52380277B563C89847B901/`).
- `owner()` read through this proxy currently resolves directly to the Gnosis
  Safe (`0x912008f7f56650bFcBa8102cdCD8ABD889769997`) — unlike
  `GovernanceProxy_0xc2D8595.../`, which delegates day-to-day `owner()` control
  to a separate hot EOA, this one keeps `Ownable` control with the Safe itself.
