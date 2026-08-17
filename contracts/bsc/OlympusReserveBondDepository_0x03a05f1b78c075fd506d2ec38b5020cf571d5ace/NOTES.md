# Olympus Reserve BondDepository (impl) — 0x03a05f1b78c075fd506d2ec38b5020cf571d5ace

- **Chain**: BNB Smart Chain (mainnet), chain ID 56
- **Role**: implementation shared by the **3 `reserveDepositor`** proxies the
  CryptoTreasury (`0xf9074b5C…`) authorizes to mint ProToken against deposited
  reserves (BSC-USD): `0xd337641111dDEB1d1F15B55c5931ECf34A7865ba`,
  `0xC56D5FEF7323332A1F2aD014cA2a8Ba22B4B1321`,
  `0xaa044262A9D25c91961260e85606fFE5f9B5E606`.
- **Verified**: **No.** Unverified contract in the value path — holds live authority
  over ProToken minting. See `../../SECURITY_AUDIT.md` Finding B and Finding A (the
  `reserveDepositor` role is also what gates the treasury's unbounded
  `destroyBondReserve` mint), and `../../UNRESOLVED.md`.

## Recovered behavior (bytecode only)

- `recovered/runtime_bytecode.hex` — runtime bytecode (8,069 bytes).
- `recovered/push4_selectors.txt` — 65 dispatcher `PUSH4` constants.
- Resolved selectors identify a **Olympus DAO V1 reserve BondDepository**:
  `bondInfo(address,uint256)`, `terms()`, `bondCount(address)`, `bondPriceInUSD()`,
  `principle()`, `pendingPayoutFor(address,uint256)`, `OHM()`, `operators(address)`,
  OZ v5 `Ownable` (`0x118cdaa7`). The plain `deposit(uint256,uint256,address)`
  selector was **not** in this dispatcher, so its user-deposit entry may use a
  different signature (unresolved) — the deposit ABI here was not pinned down.
- **Admin**: EOA `0x8533e14Caea7C622A1Dc69B9eb5f0e47b79CE6A7` (per each proxy's
  `owner()`).

## Open question

Same as the LP depository: whether an unprivileged reserve bond can mint ProToken
for less than deposited value, and — specifically for this contract — whether any
reachable path forwards into `CryptoTreasury.destroyBondReserve` with a
caller-chosen `_profit` (the unbounded-mint primitive of Finding A). Unverifiable
from bytecode; needs source/decompilation.
