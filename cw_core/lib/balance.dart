/// Balance Data class with all amounts in the lowest possible currency (e.g. satoshis or wei)
abstract class Balance {
  const Balance(this.available, this.additional, {this.secondAvailable, this.secondAdditional, this.frozen});

  Balance.fromInt(int available, int additional, {int? secondAvailable, int? secondAdditional, int? frozen}) :
      available = BigInt.from(available),
  additional = BigInt.from(additional),
  secondAvailable = secondAvailable == null ? null : BigInt.from(secondAvailable),
  secondAdditional = secondAdditional == null ? null : BigInt.from(secondAdditional),
  frozen = frozen == null ? null : BigInt.from(frozen) {}



  final BigInt available;
  final BigInt additional;

  final BigInt? secondAvailable;
  final BigInt? secondAdditional;

  final BigInt? frozen;

  BigInt get fullAvailableBalance => available;

  @deprecated
  String get formattedUnAvailableBalance => '';
}
