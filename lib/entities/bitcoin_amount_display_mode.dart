import 'package:cw_core/enumerable_item.dart';

class BitcoinAmountDisplayMode extends EnumerableItem<int> with Serializable<int> {
  const BitcoinAmountDisplayMode({required String title, required int raw})
      : super(title: title, raw: raw);

  static const all = [
    BitcoinAmountDisplayMode.satoshiForLightning,
    BitcoinAmountDisplayMode.bitcoin,
    BitcoinAmountDisplayMode.satoshi,
  ];
  static const satoshiForLightning =
      BitcoinAmountDisplayMode(raw: 0, title: 'Lightning in Satoshi');
  static const bitcoin = BitcoinAmountDisplayMode(raw: 1, title: 'Bitcoin');
  static const satoshi = BitcoinAmountDisplayMode(raw: 2, title: 'Satoshi');

  static BitcoinAmountDisplayMode deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return satoshiForLightning;
      case 1:
        return bitcoin;
      case 2:
        return satoshi;
      default:
        throw Exception('Unexpected token: $raw for BalanceDisplayMode deserialize');
    }
  }

  @override
  String toString() => title;
}
