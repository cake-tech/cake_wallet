import 'package:cw_core/enumerable_item.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinSeedTypeSetting extends EnumerableItem<int> with Serializable<int> {
  const BitcoinSeedTypeSetting(this.type, {required String title, required int raw})
      : super(title: title, raw: raw);

  final DerivationType type;

  static const all = [BitcoinSeedTypeSetting.electrum, BitcoinSeedTypeSetting.bip39];

  static const defaultDerivationType = bip39;

  static const electrum = BitcoinSeedTypeSetting(DerivationType.electrum, raw: 0, title: 'Electrum');
  static const bip39 = BitcoinSeedTypeSetting(DerivationType.bip39, raw: 1, title: 'BIP39');

  static BitcoinSeedTypeSetting deserialize({required int raw}) {
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
