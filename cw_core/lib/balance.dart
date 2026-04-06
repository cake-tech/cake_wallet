import 'package:cw_core/amount/money.dart';

/// Balance Data class with all amounts in the lowest possible currency (e.g. satoshis or wei)
abstract class Balance {
  const Balance(
    this.available,
    this.additional, {
    this.secondAvailable,
    this.secondAdditional,
    this.frozen,
  });

  final Money available;
  final Money additional;

  final Money? secondAvailable;
  final Money? secondAdditional;

  final Money? frozen;

  Money get fullAvailableBalance => available;
}
