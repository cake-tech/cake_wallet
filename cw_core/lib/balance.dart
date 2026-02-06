/// Balance Data class with all amounts in the lowest possible currency (e.g. satoshis or wei)
abstract class Balance {
  const Balance(this.available, this.additional, {this.secondAvailable, this.secondAdditional, this.frozen});

  final int available;
  final int additional;

  final int? secondAvailable;
  final int? secondAdditional;

  final int? frozen;

  int get fullAvailableBalance => available;

  @deprecated
  String get formattedUnAvailableBalance => '';
}
