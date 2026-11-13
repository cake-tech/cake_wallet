import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart";
import "package:cw_bitcoin/psbt/transaction_builder.dart";

mixin BitcoinCashHardwareWalletService on BitcoinHardwareWalletService {
  Future<String> signBitcoinCashTransaction({
    required List<PSBTReadyBitcoinOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  });
}
