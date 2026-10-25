import 'package:bip39/bip39.dart' as bip39;
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart' as electrum_mnemonic;
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

/// Settles the derivation of a wallet whose saved type is [DerivationType.unknown], as left by the
/// Hive → SQLite migration or by a wallet info row recreated without its derivation.
///
/// The seed type comes from the mnemonic when it tells; otherwise from the wallet file
/// ([snapshotPath], [snapshotType]). A path that was saved is kept, so the wallet keeps deriving the
/// addresses it had. Only a wallet with no saved path gets its type's default, which for Litecoin
/// is Litecoin's own coin type.
void resolveUnknownDerivation(
  DerivationInfo derivationInfo, {
  required WalletType walletType,
  String? mnemonic,
  String? snapshotPath,
  DerivationType? snapshotType,
}) {
  final type = _seedTypeOf(mnemonic) ??
      (snapshotPath == electrum_path || snapshotType == DerivationType.electrum
          ? DerivationType.electrum
          : DerivationType.bip39);
  final savedPath = [derivationInfo.derivationPath, snapshotPath]
      .firstWhereOrNull((path) => path?.isNotEmpty ?? false);

  derivationInfo.derivationType = type;
  derivationInfo.derivationPath = savedPath ?? _defaultPath(type, walletType);
}

/// The seed type the mnemonic proves: an Electrum version prefix, or a valid BIP39 checksum. Null
/// when it's both, neither, or there is no mnemonic (hardware and watch-only wallets).
DerivationType? _seedTypeOf(String? mnemonic) {
  if (mnemonic == null || mnemonic.isEmpty) {
    return null;
  }

  final isElectrum = electrum_mnemonic.validateMnemonic(mnemonic);
  final isBip39 = bip39.validateMnemonic(mnemonic);
  if (isElectrum == isBip39) {
    return null;
  }
  return isElectrum ? DerivationType.electrum : DerivationType.bip39;
}

String _defaultPath(DerivationType type, WalletType walletType) {
  if (type == DerivationType.electrum) {
    return electrum_path;
  }
  return walletType == WalletType.litecoin ? litecoin_segwit_path : segwit_path;
}
