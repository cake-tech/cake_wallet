import 'package:cw_core/enumerable_item.dart';
import 'package:cw_core/wallet_info.dart';

class MoneroSeedType extends EnumerableItem<int> with Serializable<int> {
  const MoneroSeedType({required String title, required int raw, this.shortTitle})
      : super(title: title, raw: raw);

  final String? shortTitle;

  static const all = [legacy, polyseed, bip39];

  static const defaultSeedType = polyseed;

  static const legacy = MoneroSeedType(raw: 0, title: 'Legacy (25 words)', shortTitle: "Legacy");
  static const polyseed = MoneroSeedType(raw: 1, title: 'Polyseed (16 words)', shortTitle: "Polyseed");
  static const wowneroSeed = MoneroSeedType(raw: 2, title: 'Wownero');
  static const bip39 = MoneroSeedType(raw: 3, title: 'BIP39 (12 words)', shortTitle: "BIP39");

  static MoneroSeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return legacy;
      case 1:
        return polyseed;
      case 2:
        return wowneroSeed;
      case 3:
        return bip39;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }

  @override
  String toString() => title;
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

class NanoSeedType extends EnumerableItem<int> with Serializable<int> {
  const NanoSeedType(this.type, {required String title, required int raw})
      : super(title: title, raw: raw);

  final DerivationType type;

  static const all = [NanoSeedType.nanoStandard, NanoSeedType.bip39];

  static const defaultDerivationType = bip39;

  static const nanoStandard = NanoSeedType(DerivationType.nano, raw: 0, title: 'Nano');
  static const bip39 = NanoSeedType(DerivationType.bip39, raw: 1, title: 'BIP39');

  static NanoSeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return nanoStandard;
      case 1:
        return bip39;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }
}

class DecredSeedType extends EnumerableItem<int> with Serializable<int> {
  const DecredSeedType(this.type, {required String title, required int raw})
      : super(title: title, raw: raw);

  final DerivationType type;

  static const all = [DecredSeedType.decred, DecredSeedType.bip39];

  static const defaultDerivationType = bip39;

  static const decred = DecredSeedType(DerivationType.decred, raw: 0, title: 'Decred');
  static const bip39 = DecredSeedType(DerivationType.bip39, raw: 1, title: 'BIP39');

  static DecredSeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return decred;
      case 1:
        return bip39;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }
}
