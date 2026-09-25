# PIVX Wallet Integration for Cake Wallet

This package provides PIVX wallet functionality for Cake Wallet.

## Features

- BIP39/BIP44 HD wallet with PIVX coin type 119
- P2PKH address generation (addresses starting with 'D')
- ElectrumX backend integration
- Transaction creation and signing
- Balance tracking
- Sapling shielded transactions (addresses starting with 'ps'): send, receive, and encrypted memos, with native Rust proving/scanning

## PIVX-Specific Details

### Network Parameters (from PIVX Core)

- **Coin Type (SLIP-44):** 119
- **Derivation Path:** m/44'/119'/account'/change/index
- **P2PKH Prefix:** 30 (addresses start with 'D')
- **P2SH Prefix:** 13 (addresses start with '6')
- **Staking Prefix:** 63 (addresses start with 'S')
- **WIF Prefix:** 212
- **P2P Port:** 51472
- **RPC Port:** 51473
- **Block Time:** 60 seconds
- **Coinbase Maturity:** 100 blocks

### Transactions

- Transparent: standard P2PKH sends and receives.
- Shielded (Sapling): send, receive, and encrypted memos across every t/z combination (t to t, t to z, z to t, z to z).

Coinbase and coinstake outputs (block and stake rewards) are recognized while scanning history but are not created by the wallet.

## References

- [PIVX Core](https://github.com/PIVX-Project/PIVX)
- [SLIP-0044](https://github.com/satoshilabs/slips/blob/master/slip-0044.md)
