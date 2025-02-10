import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';

class WalletSeedData {
  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;

  WalletSeedData({required this.hdWallets});

  static Future<WalletSeedData> fromMnemonic(
    WalletInfo walletInfo,
    String mnemonic,
    BasedUtxoNetwork network, [
    String? passphrase,
  ]) async {
    final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets = {};

    for (final derivation in walletInfo.derivations ?? [walletInfo.derivationInfo!]) {
      if (derivation.derivationType == DerivationType.bip39 &&
          !hdWallets.containsKey(CWBitcoinDerivationType.bip39)) {
        try {
          final seedBytes = Bip39SeedGenerator.generateFromString(mnemonic, passphrase);
          hdWallets[CWBitcoinDerivationType.bip39] = Bip32Slip10Secp256k1.fromSeed(
            seedBytes,
            BitcoinAddressUtils.getKeyNetVersion(network),
          );
        } catch (e) {
          printV("bip39 seed error: $e");
        }

        continue;
      }

      if (derivation.derivationType == DerivationType.electrum &&
          !hdWallets.containsKey(CWBitcoinDerivationType.electrum)) {
        late List<int> seedBytes;

        try {
          seedBytes = ElectrumV2SeedGenerator.generateFromString(mnemonic, passphrase);
        } catch (e) {
          printV("electrum_v2 seed error: $e");

          try {
            seedBytes = ElectrumV1SeedGenerator(mnemonic).generate();
          } catch (e) {
            printV("electrum_v1 seed error: $e");

            try {
              seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? "");
            } catch (e) {
              printV("old electrum seed error: $e");
            }
          }
        }

        hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(
          seedBytes,
          BitcoinAddressUtils.getKeyNetVersion(network),
        );
      }
    }

    if (network == BitcoinNetwork.mainnet) {
      if (hdWallets[CWBitcoinDerivationType.bip39] != null) {
        hdWallets[CWBitcoinDerivationType.old_bip39] = hdWallets[CWBitcoinDerivationType.bip39]!;
      } else if (hdWallets[CWBitcoinDerivationType.electrum] != null) {
        hdWallets[CWBitcoinDerivationType.old_electrum] =
            hdWallets[CWBitcoinDerivationType.electrum]!;
      }
    }

    return WalletSeedData(hdWallets: hdWallets);
  }

  static WalletSeedData fromXpub(WalletInfo walletInfo, String xpub, BasedUtxoNetwork network) {
    final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets = {};

    for (final derivation in walletInfo.derivations ?? [walletInfo.derivationInfo!]) {
      if (derivation.derivationType == DerivationType.bip39) {
        hdWallets[CWBitcoinDerivationType.bip39] = Bip32Slip10Secp256k1.fromExtendedKey(
          xpub,
          BitcoinAddressUtils.getKeyNetVersion(network),
        );
      } else if (derivation.derivationType == DerivationType.electrum) {
        hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromExtendedKey(
          xpub,
          BitcoinAddressUtils.getKeyNetVersion(network),
        );
      }
    }

    if (hdWallets[CWBitcoinDerivationType.bip39] != null) {
      hdWallets[CWBitcoinDerivationType.old_bip39] = hdWallets[CWBitcoinDerivationType.bip39]!;
    }
    if (hdWallets[CWBitcoinDerivationType.electrum] != null) {
      hdWallets[CWBitcoinDerivationType.old_electrum] =
          hdWallets[CWBitcoinDerivationType.electrum]!;
    }

    return WalletSeedData(hdWallets: hdWallets);
  }
}
