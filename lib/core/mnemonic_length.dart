import 'package:cake_wallet/src/domain/common/wallet_type.dart';

const bitcoinMnemonicLength = 12;
const moneroMnemonicLength = 25;

int mnemonicLength(WalletType type) {
  // TODO: need to have only one place for get(set) mnemonic string lenth;

  switch (type) {
    case WalletType.monero:
      return moneroMnemonicLength;
    case WalletType.bitcoin:
      return bitcoinMnemonicLength;
    default:
      return 0;
  }
}