import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';

class WalletSeedBytes {
  final List<int> seedBytes;
  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;

  WalletSeedBytes({required this.seedBytes, required this.hdWallets});

  static Future<WalletSeedBytes> getSeedBytes(
    WalletInfo walletInfo,
    String mnemonic, [
    String? passphrase,
  ]) async {
    late List<int> seedBytes;
    final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets = {};

    for (final derivation in walletInfo.derivations ?? [walletInfo.derivationInfo!]) {
      if (derivation.derivationType == DerivationType.bip39) {
        try {
          seedBytes = Bip39SeedGenerator.generateFromString(mnemonic, passphrase);
          hdWallets[CWBitcoinDerivationType.bip39] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
        } catch (e) {
          printV("bip39 seed error: $e");
        }

        continue;
      }

      if (derivation.derivationType == DerivationType.electrum) {
        try {
          seedBytes = ElectrumV2SeedGenerator.generateFromString(mnemonic, passphrase);
          hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
        } catch (e) {
          printV("electrum_v2 seed error: $e");

          try {
            seedBytes = ElectrumV1SeedGenerator(mnemonic).generate();
            hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
          } catch (e) {
            printV("electrum_v1 seed error: $e");
          }
        }
      }
    }

    if (hdWallets[CWBitcoinDerivationType.bip39] != null) {
      hdWallets[CWBitcoinDerivationType.old_bip39] = hdWallets[CWBitcoinDerivationType.bip39]!;
    }
    if (hdWallets[CWBitcoinDerivationType.electrum] != null) {
      hdWallets[CWBitcoinDerivationType.old_electrum] =
          hdWallets[CWBitcoinDerivationType.electrum]!;
    }

    return WalletSeedBytes(seedBytes: seedBytes, hdWallets: hdWallets);
  }
}
