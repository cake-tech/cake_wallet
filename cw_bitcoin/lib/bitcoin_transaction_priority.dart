import 'package:cw_core/transaction_priority.dart';

class BitcoinAPITransactionPriority extends TransactionPriority {
  const BitcoinAPITransactionPriority({required super.title, required super.raw});

// Unimportant: the lowest possible, confirms when it confirms no matter how long it takes
  static const BitcoinAPITransactionPriority unimportant =
      BitcoinAPITransactionPriority(title: 'Unimportant', raw: 0);
// Normal: low fee, confirms in a reasonable time, normal because in most cases more than this is not needed, gets you in the next 2-3 blocks (about 1 hour)
  static const BitcoinAPITransactionPriority normal =
      BitcoinAPITransactionPriority(title: 'Normal', raw: 1);
// Elevated: medium fee, confirms soon, elevated because it's higher than normal, gets you in the next 1-2 blocks (about 30 mins)
  static const BitcoinAPITransactionPriority elevated =
      BitcoinAPITransactionPriority(title: 'Elevated', raw: 2);
// Priority: high fee, expected in the next block (about 10 mins).
  static const BitcoinAPITransactionPriority priority =
      BitcoinAPITransactionPriority(title: 'Priority', raw: 3);
// Custom: any fee, user defined
  static const BitcoinAPITransactionPriority custom =
      BitcoinAPITransactionPriority(title: 'Custom', raw: 4);

  static BitcoinAPITransactionPriority deserialize({required int raw}) {
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
        throw Exception('Unexpected token: $raw for BitcoinTransactionPriority deserialize');
    }
  }

  @override
  String toString() {
    var label = '';

    switch (this) {
      case BitcoinAPITransactionPriority.unimportant:
        label = 'Unimportant ~24hrs+'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case BitcoinAPITransactionPriority.normal:
        label = 'Normal ~1hr+'; // S.current.transaction_priority_medium;
        break;
      case BitcoinAPITransactionPriority.elevated:
        label = 'Elevated';
        break; // S.current.transaction_priority_fast;
      case BitcoinAPITransactionPriority.priority:
        label = 'Priority';
        break; // S.current.transaction_priority_fast;
      case BitcoinAPITransactionPriority.custom:
        label = 'Custom';
        break;
      default:
        break;
    }

    return label;
  }

  String labelWithRate(int rate, int? customRate) {
    final rateValue = this == custom ? customRate ??= 0 : rate;
    return '${toString()} ($rateValue ${getUnits(rateValue)}/byte)';
  }
}

class ElectrumTransactionPriority extends TransactionPriority {
  const ElectrumTransactionPriority({required String title, required int raw})
      : super(title: title, raw: raw);

  static const List<ElectrumTransactionPriority> all = [fast, medium, slow, custom];

  static const ElectrumTransactionPriority slow =
      ElectrumTransactionPriority(title: 'Slow', raw: 0);
  static const ElectrumTransactionPriority medium =
      ElectrumTransactionPriority(title: 'Medium', raw: 1);
  static const ElectrumTransactionPriority fast =
      ElectrumTransactionPriority(title: 'Fast', raw: 2);
  static const ElectrumTransactionPriority custom =
      ElectrumTransactionPriority(title: 'Custom', raw: 3);

  static ElectrumTransactionPriority deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return slow;
      case 1:
        return medium;
      case 2:
        return fast;
      case 3:
        return custom;
      default:
        throw Exception('Unexpected token: $raw for ElectrumTransactionPriority deserialize');
    }
  }

  String get units => 'sat';

  @override
  String toString() {
    var label = '';

    switch (this) {
      case ElectrumTransactionPriority.slow:
        label = 'Slow ~24hrs+'; // '${S.current.transaction_priority_slow} ~24hrs';
        break;
      case ElectrumTransactionPriority.medium:
        label = 'Medium'; // S.current.transaction_priority_medium;
        break;
      case ElectrumTransactionPriority.fast:
        label = 'Fast';
        break; // S.current.transaction_priority_fast;
      case ElectrumTransactionPriority.custom:
        label = 'Custom';
        break;
      default:
        break;
    }

    return label;
  }

  String labelWithRate(int rate, int? customRate) {
    final rateValue = this == custom ? customRate ??= 0 : rate;
    return '${toString()} ($rateValue ${getUnits(rateValue)}/byte)';
  }
}

class LitecoinTransactionPriority extends ElectrumTransactionPriority {
  const LitecoinTransactionPriority({required super.title, required super.raw});

  @override
  String get units => 'lit';
}

class BitcoinCashTransactionPriority extends ElectrumTransactionPriority {
  const BitcoinCashTransactionPriority({required super.title, required super.raw});

  @override
  String get units => 'satoshi';
}

class BitcoinAPITransactionPriorities implements TransactionPriorities {
  const BitcoinAPITransactionPriorities({
    required this.unimportant,
    required this.normal,
    required this.elevated,
    required this.priority,
    required this.custom,
  });

  final int unimportant;
  final int normal;
  final int elevated;
  final int priority;
  final int custom;

  @override
  int operator [](TransactionPriority type) {
    switch (type) {
      case BitcoinAPITransactionPriority.unimportant:
        return unimportant;
      case BitcoinAPITransactionPriority.normal:
        return normal;
      case BitcoinAPITransactionPriority.elevated:
        return elevated;
      case BitcoinAPITransactionPriority.priority:
        return priority;
      case BitcoinAPITransactionPriority.custom:
        return custom;
      default:
        throw Exception('Unexpected token: $type for TransactionPriorities operator[]');
    }
  }

  @override
  String labelWithRate(TransactionPriority priorityType, [int? rate]) {
    late int rateValue;

    if (priorityType == BitcoinAPITransactionPriority.custom) {
      if (rate == null) {
        throw Exception('Rate must be provided for custom transaction priority');
      }
      rateValue = rate;
    } else {
      rateValue = this[priorityType];
    }

    return '${priorityType.toString()} (${rateValue} ${priorityType.getUnits(rateValue)}/byte)';
  }

  @override
  Map<String, int> toJson() {
    return {
      'unimportant': unimportant,
      'normal': normal,
      'elevated': elevated,
      'priority': priority,
      'custom': custom,
    };
  }

  static BitcoinAPITransactionPriorities fromJson(Map<String, dynamic> json) {
    return BitcoinAPITransactionPriorities(
      unimportant: json['unimportant'] as int,
      normal: json['normal'] as int,
      elevated: json['elevated'] as int,
      priority: json['priority'] as int,
      custom: json['custom'] as int,
    );
  }
}

class ElectrumTransactionPriorities implements TransactionPriorities {
  const ElectrumTransactionPriorities({
    required this.slow,
    required this.medium,
    required this.fast,
    required this.custom,
  });

  final int slow;
  final int medium;
  final int fast;
  final int custom;

  @override
  int operator [](TransactionPriority type) {
    switch (type) {
      case ElectrumTransactionPriority.slow:
        return slow;
      case ElectrumTransactionPriority.medium:
        return medium;
      case ElectrumTransactionPriority.fast:
        return fast;
      case ElectrumTransactionPriority.custom:
        return custom;
      default:
        throw Exception('Unexpected token: $type for TransactionPriorities operator[]');
    }
  }

  @override
  String labelWithRate(TransactionPriority priorityType, [int? rate]) {
    final rateValue = this[priorityType];
    return '${priorityType.toString()} ($rateValue ${priorityType.getUnits(rateValue)}/byte)';
  }

  factory ElectrumTransactionPriorities.fromList(List<int> list) {
    if (list.length != 3) {
      throw Exception(
          'Unexpected list length: ${list.length} for BitcoinElectrumTransactionPriorities.fromList');
    }

    return ElectrumTransactionPriorities(
      slow: list[0],
      medium: list[1],
      fast: list[2],
      custom: 0,
    );
  }

  @override
  Map<String, int> toJson() {
    return {
      'slow': slow,
      'medium': medium,
      'fast': fast,
      'custom': custom,
    };
  }

  static ElectrumTransactionPriorities fromJson(Map<String, dynamic> json) {
    return ElectrumTransactionPriorities(
      slow: json['slow'] as int,
      medium: json['medium'] as int,
      fast: json['fast'] as int,
      custom: json['custom'] as int,
    );
  }
}

TransactionPriorities deserializeTransactionPriorities(Map<String, dynamic> json) {
  if (json.containsKey('unimportant')) {
    return BitcoinAPITransactionPriorities.fromJson(json);
  } else if (json.containsKey('slow')) {
    return ElectrumTransactionPriorities.fromJson(json);
  } else {
    throw Exception('Unexpected token: $json for deserializeTransactionPriorities');
  }
}
