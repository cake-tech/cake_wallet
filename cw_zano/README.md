# cw_zano

Zano wallet module for Cake Wallet. Provides a Dart wrapper around the Zano wallet API with typed models and transaction helpers.

## Features

- Wallet lifecycle and status queries via `ZanoWalletApi`.
- Typed models for balances, transfers, recent history, and wallet info.
- Build and submit transfers; pending transaction modeling.
- Address and asset utilities, formatter helpers.

## Usage

See `lib/zano_wallet_api.dart` and `lib/zano_wallet.dart` for the high-level API. Typical flow:

```dart
final api = ZanoWalletApi();
final info = await api.getWalletInfo();
final balance = await api.getBalance();
// create transfer params and broadcast
```

Consult `lib/api/model/` for full set of supported request/response models.
