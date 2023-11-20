import 'package:cake_wallet/generated/i18n.dart';

enum SeedPhraseLength {
  twelveWords(12),
  twentyFourWords(24);

  const SeedPhraseLength(this.value);
  final int value;

  static SeedPhraseLength deserialize({required int raw}) =>
      SeedPhraseLength.values.firstWhere((e) => e.value == raw);

  @override
  String toString() {
    String label = '';
    switch (this) {
      case SeedPhraseLength.twelveWords:
        label = '12 Words';
        break;
      case SeedPhraseLength.twentyFourWords:
        label = '24 Words';
        break;
    }
    return label;
  }
}