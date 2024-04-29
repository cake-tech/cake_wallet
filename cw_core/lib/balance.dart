abstract class Balance {
  const Balance(this.available, this.additional);

  final int available;

  final int additional;

  String get formattedAvailableBalance;

  String get formattedFullBalance;

  String get formattedAdditionalBalance => '';

  String get formattedUnAvailableBalance => '';
}
