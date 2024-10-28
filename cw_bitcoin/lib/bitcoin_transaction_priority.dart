import 'package:cw_core/transaction_priority.dart';

// Unimportant: the lowest possible, confirms when it confirms no matter how long it takes
// Normal: low fee, confirms in a reasonable time, normal because in most cases more than this is not needed, gets you in the next 2-3 blocks (about 1 hour)
// Elevated: medium fee, confirms soon, elevated because it's higher than normal, gets you in the next 1-2 blocks (about 30 mins)
// Priority: high fee, expected in the next block (about 10 mins).

class BitcoinMempoolAPITransactionPriority extends TransactionPriority {
  const BitcoinMempoolAPITransactionPriority({required super.title, required super.raw});

  static const BitcoinMempoolAPITransactionPriority unimportant =
      BitcoinMempoolAPITransactionPriority(title: 'Unimportant', raw: 0);
  static const BitcoinMempoolAPITransactionPriority normal =
      BitcoinMempoolAPITransactionPriority(title: 'Normal', raw: 1);
  static const BitcoinMempoolAPITransactionPriority elevated =
      BitcoinMempoolAPITransactionPriority(title: 'Elevated', raw: 2);
  static const BitcoinMempoolAPITransactionPriority priority =
      BitcoinMempoolAPITransactionPriority(title: 'Priority', raw: 3);
  static const BitcoinMempoolAPITransactionPriority custom =
      BitcoinMempoolAPITransactionPriority(title: 'Custom', raw: 4);

  static BitcoinMempoolAPITransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return unimportant;
      case 1:
        return normal;
      case 2:
        return elevated;
      case 3:
        return priority;
      case 4:
        return custom;
      default:
        throw Exception('Unexpected token: $raw for TransactionPriority deserialize');
    }
  }

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinMempoolAPITransactionPriority.unimportant:
        label = 'Unimportant ~24hrs+'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case BitcoinMempoolAPITransactionPriority.normal:
        label = 'Normal ~1hr+'; // S.current.transaction_priority_medium;
        break;
      case BitcoinMempoolAPITransactionPriority.elevated:
        label = 'Elevated';
        break; // S.current.transaction_priority_fast;
      case BitcoinMempoolAPITransactionPriority.priority:
        label = 'Priority';
        break; // S.current.transaction_priority_fast;
      case BitcoinMempoolAPITransactionPriority.custom:
        label = 'Custom';
        break;
      default:
        break;
    }

    return label;
  }

  String labelWithRate(int rate, int? customRate) {
    final rateValue = this == custom ? customRate ??= 0 : rate;
    return '${toString()} ($rateValue ${units}/byte)';
  }
}

class BitcoinElectrumTransactionPriority extends TransactionPriority {
  const BitcoinElectrumTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<BitcoinElectrumTransactionPriority> all = [
    unimportant,
    normal,
    elevated,
    priority,
    custom,
  ];

  static const BitcoinElectrumTransactionPriority unimportant =
      BitcoinElectrumTransactionPriority(title: 'Unimportant', raw: 0);
  static const BitcoinElectrumTransactionPriority normal =
      BitcoinElectrumTransactionPriority(title: 'Normal', raw: 1);
  static const BitcoinElectrumTransactionPriority elevated =
      BitcoinElectrumTransactionPriority(title: 'Elevated', raw: 2);
  static const BitcoinElectrumTransactionPriority priority =
      BitcoinElectrumTransactionPriority(title: 'Priority', raw: 3);
  static const BitcoinElectrumTransactionPriority custom =
      BitcoinElectrumTransactionPriority(title: 'Custom', raw: 4);

  static BitcoinElectrumTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return unimportant;
      case 1:
        return normal;
      case 2:
        return elevated;
      case 3:
        return priority;
      case 4:
        return custom;
      default:
        throw Exception('Unexpected token: $raw for TransactionPriority deserialize');
    }
  }

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinElectrumTransactionPriority.unimportant:
        label = 'Unimportant'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case BitcoinElectrumTransactionPriority.normal:
        label = 'Slow ~24hrs+'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case BitcoinElectrumTransactionPriority.elevated:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break; // S.current.transaction_priority_fast;
      case BitcoinElectrumTransactionPriority.priority:
        label = 'Fast';
        break; // S.current.transaction_priority_fast;
      case BitcoinElectrumTransactionPriority.custom:
        label = 'Custom';
        break;
      default:
        break;
    }

    return label;
  }

  String labelWithRate(int rate, int? customRate) {
    final rateValue = this == custom ? customRate ??= 0 : rate;
    return '${toString()} ($rateValue ${units}/byte)';
  }
}

class LitecoinTransactionPriority extends BitcoinElectrumTransactionPriority {
  const LitecoinTransactionPriority({required super.title, required super.raw});

  static const all = [slow, medium, fast];

  static const LitecoinTransactionPriority slow =
      LitecoinTransactionPriority(title: 'Slow', raw: 0);
  static const LitecoinTransactionPriority medium =
      LitecoinTransactionPriority(title: 'Medium', raw: 1);
  static const LitecoinTransactionPriority fast =
      LitecoinTransactionPriority(title: 'Fast', raw: 2);

  static LitecoinTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for LitecoinTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'lit';
}

class BitcoinCashTransactionPriority extends BitcoinElectrumTransactionPriority {
  const BitcoinCashTransactionPriority({required super.title, required super.raw});

  static const all = [slow, medium, fast];

  static const BitcoinCashTransactionPriority slow =
      BitcoinCashTransactionPriority(title: 'Slow', raw: 0);
  static const BitcoinCashTransactionPriority medium =
      BitcoinCashTransactionPriority(title: 'Medium', raw: 1);
  static const BitcoinCashTransactionPriority fast =
      BitcoinCashTransactionPriority(title: 'Fast', raw: 2);

  static BitcoinCashTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      default:
        throw Exception('Unexpected token: $raw for LitecoinTransactionPriority deserialize');
    }
  }

  @override
  String get units => 'satoshi';
}

class BitcoinMempoolAPITransactionPriorities implements TransactionPriorities {
  const BitcoinMempoolAPITransactionPriorities({
    required this.unimportant,
    required this.normal,
    required this.elevated,
    required this.priority,
  });

  final int unimportant;
  final int normal;
  final int elevated;
  final int priority;

  @override
  int operator [](TransactionPriority type) {
    switch (type) {
      case BitcoinMempoolAPITransactionPriority.unimportant:
        return unimportant;
      case BitcoinMempoolAPITransactionPriority.normal:
        return normal;
      case BitcoinMempoolAPITransactionPriority.elevated:
        return elevated;
      case BitcoinMempoolAPITransactionPriority.priority:
        return priority;
      default:
        throw Exception('Unexpected token: $type for TransactionPriorities operator[]');
    }
  }

  @override
  String labelWithRate(TransactionPriority priorityType, [int? rate]) {
    late int rateValue;

    if (priorityType == BitcoinMempoolAPITransactionPriority.custom) {
      if (rate == null) {
        throw Exception('Rate must be provided for custom transaction priority');
      }
      rateValue = rate;
    } else {
      rateValue = this[priorityType];
    }

    return '${priorityType.toString()} (${rateValue} ${priorityType.units}/byte)';
  }
}

class BitcoinElectrumTransactionPriorities implements TransactionPriorities {
  const BitcoinElectrumTransactionPriorities({
    required this.unimportant,
    required this.slow,
    required this.medium,
    required this.fast,
  });

  final int unimportant;
  final int slow;
  final int medium;
  final int fast;

  @override
  int operator [](TransactionPriority type) {
    switch (type) {
      case BitcoinElectrumTransactionPriority.unimportant:
        return unimportant;
      case BitcoinElectrumTransactionPriority.normal:
        return slow;
      case BitcoinElectrumTransactionPriority.elevated:
        return medium;
      case BitcoinElectrumTransactionPriority.priority:
        return fast;
      default:
        throw Exception('Unexpected token: $type for TransactionPriorities operator[]');
    }
  }

  @override
  String labelWithRate(TransactionPriority priorityType, [int? rate]) {
    return '${priorityType.toString()} (${this[priorityType]} ${priorityType.units}/byte)';
  }

  factory BitcoinElectrumTransactionPriorities.fromList(List<int> list) {
    if (list.length != 3) {
      throw Exception(
          'Unexpected list length: ${list.length} for BitcoinElectrumTransactionPriorities.fromList');
    }

    int unimportantFee = list[0];

    // Electrum servers only provides 3 levels: slow, medium, fast
    // so make "unimportant" always lower than slow (but not 0)
    if (unimportantFee > 1) {
      unimportantFee--;
    }

    return BitcoinElectrumTransactionPriorities(
      unimportant: unimportantFee,
      slow: list[0],
      medium: list[1],
      fast: list[2],
    );
  }
}
