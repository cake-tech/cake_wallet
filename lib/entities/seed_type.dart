import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';
import 'package:cw_core/wallet_info.dart';

class MoneroSeedType extends EnumerableItem<int> with Serializable<int> {
  const MoneroSeedType({required String title, required int raw}) : super(title: title, raw: raw);

  static const all = [MoneroSeedType.legacy, MoneroSeedType.polyseed];

  static const defaultSeedType = polyseed;

  static const legacy = MoneroSeedType(raw: 0, title: 'Legacy (25 words)');
  static const polyseed = MoneroSeedType(raw: 1, title: 'Polyseed (16 words)');
  static const wowneroSeed = MoneroSeedType(raw: 2, title: 'Wownero (14 words)');

  static MoneroSeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return legacy;
      case 1:
        return polyseed;
      case 2:
        return wowneroSeed;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case MoneroSeedType.legacy:
        return S.current.seedtype_legacy;
      case MoneroSeedType.polyseed:
        return S.current.seedtype_polyseed;
      case MoneroSeedType.wowneroSeed:
        return S.current.seedtype_wownero;
      default:
        return '';
    }
  }
}

class BitcoinSeedType extends EnumerableItem<int> with Serializable<int> {
  const BitcoinSeedType(this.type, {required String title, required int raw})
      : super(title: title, raw: raw);

  final DerivationType type;

  static const all = [BitcoinSeedType.electrum, BitcoinSeedType.bip39];

  static const defaultDerivationType = bip39;

  static const electrum = BitcoinSeedType(DerivationType.electrum, raw: 0, title: 'Electrum');
  static const bip39 = BitcoinSeedType(DerivationType.bip39, raw: 1, title: 'BIP39');

  static BitcoinSeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return electrum;
      case 1:
        return bip39;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }
}
