import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_bitcoin/bitcoin_mnemonic.dart' as electrum_mnemonic;
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/unknown_derivation.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Electrum segwit version prefix, invalid BIP39 checksum: what every pre-2024 Cake wallet has.
const _electrumSeed = 'flag maid surge feel hundred awkward burger logic '
    'maple whale monkey road ribbon practice inside provide '
    'insane letter sorry choice zebra purse copy mention';

/// Valid BIP39 checksum, no Electrum version prefix.
const _bip39Seed = 'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

/// Valid BIP39 checksum whose version hash also carries a prefix the Electrum validator accepts:
/// the mnemonic proves nothing.
const _ambiguousSeed = 'immune boat rice detect proof link disagree help '
    'crouch multiply poet glove fabric fee begin lesson '
    'hospital forum web beyond army blossom never brother';

DerivationInfo _unknown({String? path}) =>
    DerivationInfo(derivationType: DerivationType.unknown, derivationPath: path);

void main() {
  test('fixtures are what they claim', () {
    expect(electrum_mnemonic.validateMnemonic(_electrumSeed), isTrue);
    expect(bip39.validateMnemonic(_electrumSeed), isFalse);
    expect(electrum_mnemonic.validateMnemonic(_bip39Seed), isFalse);
    expect(bip39.validateMnemonic(_bip39Seed), isTrue);
    expect(electrum_mnemonic.validateMnemonic(_ambiguousSeed), isTrue);
    expect(bip39.validateMnemonic(_ambiguousSeed), isTrue);
  });

  group('type', () {
    test("the wallet file's recorded type wins over the mnemonic", () {
      // A BIP39 phrase restored with Electrum stretching, whose row was recreated without its
      // derivation: the file still says what the wallet has been deriving with.
      final electrum = _unknown();
      resolveUnknownDerivation(electrum,
          walletType: WalletType.bitcoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.electrum,
          snapshotPath: electrum_path);
      expect(electrum.derivationType, DerivationType.electrum);
      expect(electrum.derivationPath, electrum_path);

      final litecoin = _unknown();
      resolveUnknownDerivation(litecoin,
          walletType: WalletType.litecoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.bip39,
          snapshotPath: "m/84'/2'/0'");
      expect(litecoin.derivationType, DerivationType.bip39);
      expect(litecoin.derivationPath, "m/84'/2'/0'");
    });

    test('a file that predates derivation tracking loads as electrum, which such wallets used', () {
      for (final seed in [_electrumSeed, _ambiguousSeed]) {
        final wallet = _unknown();
        resolveUnknownDerivation(wallet,
            walletType: WalletType.bitcoin,
            mnemonic: seed,
            // ElectrumWalletSnapshot.load defaults absent fields to these.
            snapshotType: DerivationType.electrum,
            snapshotPath: electrum_path);
        expect(wallet.derivationType, DerivationType.electrum, reason: seed);
        expect(wallet.derivationPath, electrum_path, reason: seed);
      }
    });

    test('the mnemonic decides when the file still says unknown or there is no file', () {
      // v5.6.0–v5.6.4 saved migrated rows as (unknown, '').
      final dormant = _unknown(path: '');
      resolveUnknownDerivation(dormant,
          walletType: WalletType.bitcoin,
          mnemonic: _electrumSeed,
          snapshotType: DerivationType.unknown,
          snapshotPath: '');
      expect(dormant.derivationType, DerivationType.electrum);
      expect(dormant.derivationPath, electrum_path);

      final noFileElectrum = _unknown();
      resolveUnknownDerivation(noFileElectrum,
          walletType: WalletType.bitcoin, mnemonic: _electrumSeed);
      expect(noFileElectrum.derivationType, DerivationType.electrum);
      expect(noFileElectrum.derivationPath, electrum_path);

      final noFileBip39 = _unknown();
      resolveUnknownDerivation(noFileBip39, walletType: WalletType.bitcoin, mnemonic: _bip39Seed);
      expect(noFileBip39.derivationType, DerivationType.bip39);
      expect(noFileBip39.derivationPath, segwit_path);
    });

    test('without a usable mnemonic the old fallback applies', () {
      // Hardware and watch-only wallets have no mnemonic; an ambiguous one proves nothing.
      final electrumPath = _unknown();
      resolveUnknownDerivation(electrumPath,
          walletType: WalletType.bitcoin,
          snapshotType: DerivationType.unknown,
          snapshotPath: electrum_path);
      expect(electrumPath.derivationType, DerivationType.electrum);
      expect(electrumPath.derivationPath, electrum_path);

      final ambiguousNoFile = _unknown();
      resolveUnknownDerivation(ambiguousNoFile,
          walletType: WalletType.bitcoin, mnemonic: _ambiguousSeed);
      expect(ambiguousNoFile.derivationType, DerivationType.bip39);
      expect(ambiguousNoFile.derivationPath, segwit_path);

      final nothing = _unknown();
      resolveUnknownDerivation(nothing, walletType: WalletType.bitcoin);
      expect(nothing.derivationType, DerivationType.bip39);
      expect(nothing.derivationPath, segwit_path);
    });
  });

  group('path', () {
    test("a saved path is kept, the row's before the wallet file's", () {
      final fromRow = _unknown(path: "m/44'/0'/0'");
      resolveUnknownDerivation(fromRow,
          walletType: WalletType.bitcoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.bip39,
          snapshotPath: segwit_path);
      expect(fromRow.derivationPath, "m/44'/0'/0'");

      final fromFile = _unknown(path: '');
      resolveUnknownDerivation(fromFile,
          walletType: WalletType.litecoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.bip39,
          snapshotPath: "m/84'/2'/0'");
      expect(fromFile.derivationPath, "m/84'/2'/0'");
    });

    test("with no path anywhere the type's default applies, Litecoin on its own coin type", () {
      final bitcoin = _unknown(path: '');
      resolveUnknownDerivation(bitcoin,
          walletType: WalletType.bitcoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.unknown,
          snapshotPath: '');
      expect(bitcoin.derivationPath, segwit_path);

      final litecoin = _unknown();
      resolveUnknownDerivation(litecoin,
          walletType: WalletType.litecoin,
          mnemonic: _bip39Seed,
          snapshotType: DerivationType.unknown,
          snapshotPath: '');
      expect(litecoin.derivationPath, litecoin_segwit_path);

      final electrum = _unknown();
      resolveUnknownDerivation(electrum, walletType: WalletType.litecoin, mnemonic: _electrumSeed);
      expect(electrum.derivationPath, electrum_path);
    });
  });
}
