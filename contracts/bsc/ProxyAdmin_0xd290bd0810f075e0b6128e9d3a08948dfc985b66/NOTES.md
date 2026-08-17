# ProxyAdmin — 0xd290bd0810f075e0b6128e9d3a08948dfc985b66

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: `ProxyAdmin` for `GovernanceProxy_0xc2D8595.../` (CDaoToken's
  `governance` proxy) and for `TreasuryProxy_0xf9074b5C.../`. Whoever owns this
  contract can replace either proxy's implementation with anything, at will —
  the single highest-leverage authority found over the "governance" side of
  CDAO's trust graph.
- **Verified**: **No.** Etherscan has no source for this address.
- **No separate source folder**: there is nothing to save beyond the bytecode
  characterization below — see `../../UNRESOLVED.md` if a byte-for-byte source
  match becomes available later.

## Recovered/inferred behavior

- **`owner()` → `0x912008f7f56650bFcBa8102cdCD8ABD889769997`** (the 19-of-32
  Gnosis Safe — see `GnosisSafe19of32_.../`), read via direct `eth_call`.
- Bytecode length 879 bytes; exposes standard OpenZeppelin `Ownable` selectors
  (`owner()`, `renounceOwnership()`, `transferOwnership(address)`) plus a
  3-argument `upgradeAndCall(address proxy, address implementation, bytes data)`
  at selector `0x9623609d`.
- **Confirmed empirically and via chain history that this exact function was
  called** by the Gnosis Safe on 2026-06-30 (Safe tx nonce 16,
  `0xd87ee9249949600829bd4d94e9c80c49572808b62aa0cd840384c301563f4911`) with
  `(proxy=0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13, implementation=0xD50Eda29d59B207d6FbA31b4CFC1eFC76276e888, data=0x)`,
  and separately (Safe tx nonce 13, 2026-06-09) against
  `TreasuryProxy_0xf9074b5C.../` with implementation
  `0xE6fa68BA6c32F2C18C52380277B563C89847B901`.
- Not independently compiled/bytecode-matched against OpenZeppelin's
  `ProxyAdmin.sol` (which was recovered as a dependency of the *verified*
  `GovernanceProxy_0xc2D8595.../` source bundle) — treat "this is very likely a
  stock, unverified OZ v5.5.0 `ProxyAdmin` deployment" as a strong inference
  from behavior, not a confirmed source match. An audit with a local toolchain
  should compile `ProxyAdmin.sol` from that bundle with `solc 0.8.30` and diff
  the resulting bytecode against this address's `eth_getCode` output to close
  this out.

## Why this matters

This contract, not CDaoToken's own `owner()`/`governance()` variables, is the
real backstop authority over whatever logic ends up running at
`0xc2D8595Fe8D904a8665059D68A6fa2467dF09A13` — the address holding 32.9% of
CDAO's total supply. Nothing in CDaoToken's source names this contract; it was
only found by walking outward from the `governance` address.
