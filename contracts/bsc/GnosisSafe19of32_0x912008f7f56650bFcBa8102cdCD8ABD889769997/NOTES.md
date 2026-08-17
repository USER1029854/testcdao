# Gnosis Safe (19-of-32) — 0x912008f7f56650bFcBa8102cdCD8ABD889769997

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: `owner()` of `ProxyAdmin_0xd290bd0810f075e0b6128e9d3a08948dfc985b66`
  (and therefore the ultimate upgrade authority over
  `GovernanceProxy_0xc2D8595.../` and `TreasuryProxy_0xf9074b5C.../`); `owner()`
  of `UnnamedTreasuryProxy_0xC0021e08.../` at the storage/proxy level. The
  single highest-leverage identity in this trust graph.
- **Verified**: standard Gnosis Safe v1.4.1+L2 singleton pattern
  (`masterCopy` / minimal proxy at slot 0 → `0x29fcB43b46531BcA003ddC8FCB67FFE91900C762`).
  Confirmed live via both direct `eth_call` (`getThreshold()`, `getOwners()`,
  `VERSION()`) and Safe's own transaction-service API
  (`https://safe-transaction-bsc.safe.global/api/v1/safes/<address>/`), which
  independently agree.
- **No source folder**: this is a well-known, standard, publicly-audited
  contract pattern (Gnosis/Safe's own `GnosisSafeProxy` + singleton), not
  bespoke code — recorded here as configuration/authority state rather than a
  source dump.

## Current configuration

- **Threshold: 19 of 32.**
- **Nonce 21** (21 executed transactions, all successful), 2026-03-11 →
  2026-08-09.
- Fallback handler: `0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99`. No modules,
  no guard.
- Full owner list (32 addresses, as of this snapshot):
  `0x654E4bE59419EDF885fe3c5dbEd5a4960dd40Bd9`,
  `0xfaf79D8C72a54ae36100b82F95645C57EaD67864`,
  `0x4f79f91789F4e4f7f6Cd98BaeC508325f9707D88`,
  `0x8578Bf8F45E0D03b9915EB6fa11283b73F4A174C`,
  `0x84cdD8D5868e8827AAce65Ba4406dE0836295496`,
  `0xfc6298434B9DeB83A5c0acf5FDDFFc9D981f0dC9`,
  `0x13F1700Ba532a9eF3D9F1eC3A0b2f527C99593BF`,
  `0x4AFa4556E5AB597b633808D82E1e0ce9458522F9`,
  `0xd4120E0C0527cF3A20FECE73fc456e6666666666`,
  `0x18432556f5734322231f4f61F5219f23e09BB1dc`,
  `0xA4190d3e4dbC5fADa276BAe9D3618E2409Be1cA7`,
  `0x2092ddafD81FF1e32f0BB89B1743d789c1C9F2CC`,
  `0x8BF499C0741F88dB46F2E7E0Dbf331fdff564d40`,
  `0x2400404f1dacF704D7A0BF68878FC340Bc97D17e`,
  `0x180ac6c3F5Fd0B7cC0515720929e7f7edc621bBF`,
  `0x878413D6447a0f4B9124162b00Cf0b5A3103E40b`,
  `0xa831E45064845A86BE3E1ce8ae9CA6F47cBe785d`,
  `0xc9bd996305227C9e59Faf9d08c3963f4B39FaA60`,
  `0x602f119E0515c066a89d72F2f62567aA1EDc9A88`,
  `0x926E17a0BDFE9F5E7cb42E78D879DC99Cd947b54`,
  `0x85DC89939c9F82958825D75680ce782afe818ad4`,
  `0xbc4A952354E93E8298470ff387520469090e7025`,
  `0x7d38AB50190106e77F382F360268Ea2Ac233C623` (★ see below),
  `0x8CFE8A4579429cF9826de8dCC6cBA1D27210790D`,
  `0x3AB5B452aE9Ea82d718CeA2cf07E3eA3673b26d1`,
  `0xe85cffb01407966aD1583E56314F5b2215a420EC`,
  `0x1B84c2705A2d7a61B84333A7377317Fdc21993a3`,
  `0x7645d8bA1918CD63Ce74FBC6353F8d1d5e3411A4`,
  `0x77b1C41E821B41e5F88C3db6203B73E8262aBF64`,
  `0xa625485500F67902186714492c019F486f2A199d`,
  `0x9653FB57cEFff7cdA209f33F22Cc3C2ada2E360f`,
  `0x4609231C8F1c68517eFc495E72B6831d537f6352`.

★ `0x7d38AB50190106e77F382F360268Ea2Ac233C623` is a Safe owner **and** the
address the Safe transferred `Ownable`-style ownership of ProToken's own
governance-proxy implementation to (`owner()` of
`ProTokenGovernanceProxy_0x96079eF9.../` resolves to this address), and the
target of `transferOwnership` calls issued against `TreasuryProxy_0xf9074b5C.../`
and `UnnamedTreasuryProxy_0xC0021e08.../` — see `../../UNRESOLVED.md` item 2 for
why the latter's current `owner()` reading doesn't actually reflect that
transfer. This address functions as a named human operator distinct from the
Safe's collective authority.

## Notable transaction history (from Safe transaction service, all executed & successful)

| nonce | date (UTC) | target | action |
|---|---|---|---|
| 20 | 2026-08-09 | `0xC0021e0849faDefB98761f40829009905Dbd8Ee8` | raw call, selector `0x83d58474`, not decoded by Safe UI — see `UNRESOLVED.md` item 2 |
| 19,18,17 | 2026-07-10 | BSC-USD (`0x55d398326f99059fF775485246999027B3197955`) | plain `transfer()` to 3 different recipients |
| 16 | 2026-06-30 | ProxyAdmin (`0xd290bd0810f075e0b6128e9d3a08948dfc985b66`) | `upgradeAndCall(GovernanceProxy, RBSControl, "")` |
| 15 | 2026-06-11 | `0xC0021e0849faDefB98761f40829009905Dbd8Ee8` | `transferOwnership(0x7d38AB50190106e77F382F360268Ea2Ac233C623)` |
| 14 | 2026-06-11 | `TreasuryProxy_0xf9074b5C...` | `transferOwnership(0x7d38AB50190106e77F382F360268Ea2Ac233C623)` |
| 13 | 2026-06-09 | ProxyAdmin | `upgradeAndCall(TreasuryProxy, CryptoTreasury, "")` |
| 10 | 2026-05-01 | ProToken | `transferOwnership(0x...dEaD)` — ownership renounced |
| 6 | 2026-03-21 | `TreasuryProxy_0xf9074b5C...` | `transferOwnership(0x7d38AB50190106e77F382F360268Ea2Ac233C623)` (later reversed by nonce 14, or superseded — `owner()` currently reads as the Safe) |
| 5 | 2026-03-21 | `TreasuryProxy_0xf9074b5C...` | `queue(_managing=3 [RESERVEMANAGER], 0x7B09E3740B36ac42DDcdb0b174C657760d7087d5)` |
| 4,7,8,11 | Mar–May 2026 | `0x9641d764fc13c8B624c04430C7356C1C7C8102e2` (canonical Gnosis `MultiSendCallOnly`) | batched Safe owner-management (`addOwnerWithThreshold`/`changeThreshold`-style calls) |
| 2 | 2026-03-11 | self | `changeThreshold(15)` |
| 1 | 2026-03-11 | self | `addOwnerWithThreshold(0xe86b3e51096166BDd46AA305C43d20966654a64B, 3)` |

The Safe was assembled from a 1-owner/threshold-3 configuration up to
19-of-32 over roughly two weeks (nonces 0–11, March 2026), then used
operationally from June onward for the upgrades/ownership-transfers above.
