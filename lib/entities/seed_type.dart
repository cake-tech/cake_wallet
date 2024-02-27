import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/enumerable_item.dart';

class SeedType extends EnumerableItem<int> with Serializable<int> {
  const SeedType({required String title, required int raw}) : super(title: title, raw: raw);

  static const all = [SeedType.legacy, SeedType.polyseed];

  static const defaultSeedType = polyseed;

  static const legacy = SeedType(raw: 0, title: 'Legacy (25 words)');
  static const polyseed = SeedType(raw: 1, title: 'Polyseed (16 words)');

  static SeedType deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return legacy;
      case 1:
        return polyseed;
      default:
        throw Exception('Unexpected token: $raw for SeedType deserialize');
    }
  }

  @override
  String toString() {
    switch (this) {
      case SeedType.legacy:
        return S.current.seedtype_legacy;
      case SeedType.polyseed:
        return S.current.seedtype_polyseed;
      default:
        return '';
    }
  }
}
