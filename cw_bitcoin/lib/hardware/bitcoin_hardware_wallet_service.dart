import 'dart:typed_data';

import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:ledger_litecoin/ledger_litecoin.dart';

mixin BitcoinHardwareWalletService {
  Future<Uint8List> getMasterFingerprint();
}

mixin LitecoinHardwareWalletService {
  Future<String> signLitecoinTransaction({
    required List<BitcoinBaseOutput> outputs,
    required List<LedgerTransaction> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  });
}
