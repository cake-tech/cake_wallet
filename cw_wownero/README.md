# cw_wownero

Wownero wallet module for Cake Wallet, providing a Monero-family wallet with Wownero-specific APIs and bindings.

## Features

- Create/open/restore Wownero wallets; accounts and subaddresses.
- Build/sign/broadcast transactions; history and unspent outputs.
- Platform interface and method channel for native bindings.
- Exception types for setup, creation, opening, and restore flows.

## Usage

See `lib/api/` and high-level wrappers like `wownero_wallet.dart` and `wownero_wallet_service.dart` for end-to-end wallet lifecycle and usage.
