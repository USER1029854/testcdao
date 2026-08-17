# Olympus StakingDistributor (impl) — 0x62e52600d544deb350cf5564e6f1abb67213bec3

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: implementation behind the proxy
  `0x7B09E3740B36ac42DDcdb0b174C657760d7087d5`, which holds both the
  `rewardManager` and a `reserveManager` role on the CryptoTreasury
  (`0xf9074b5C…`). The `rewardManager` role can call
  `CryptoTreasury.mintRewards(_recipient, _amount)` to mint ProToken up to
  `excessReserves()`.
- **Verified**: **No.** Unverified contract in the value path. See
  `../../SECURITY_AUDIT.md` (entry-point table, `mintRewards` row) and
  `../../UNRESOLVED.md`.

## Recovered behavior (bytecode only)

- `recovered/runtime_bytecode.hex` — runtime bytecode (3,342 bytes).
- `recovered/push4_selectors.txt` — 27 dispatcher `PUSH4` constants.
- Resolved selectors identify a **canonical Olympus DAO V1 StakingDistributor**:
  `distribute()` (`0xe4fc6b6d`), `epoch()`, `epochLength()`, `nextRewardAt(uint256)`,
  `nextRewardFor(address)`, `addRecipient(address,uint256)`,
  `removeRecipient(uint256,address)`, `setAdjustment(uint256,bool,uint256,uint256)`,
  `adjustments(uint256)`, `initialize(address,address,uint256,uint256)`, OZ v5
  `Ownable`.

## Assessment

In the standard Olympus design `distribute()` is permissionless-but-idempotent (only
pays once per `epoch`, to pre-registered recipients, at admin-set rates) and simply
triggers scheduled emission via `treasury.mintRewards` — not an attacker-controllable
mint destination. `mintRewards` is additionally bounded by `excessReserves()`. The
rate/recipient config (`addRecipient`/`setAdjustment`) is owner-gated. No unprivileged
extraction is evident from behavior, but as with the bond depositories the emission
math is unverified; if the recipient list or rate could be steered to an
attacker-controlled address that would matter — unverifiable from bytecode.
