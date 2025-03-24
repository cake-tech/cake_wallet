abstract class Balance {
  const Balance(this.available, this.additional, {this.secondAvailable, this.secondAdditional, this.selected});

  final int available;

  final int additional;

  final int? secondAvailable;
  final int? secondAdditional;
  final int? selected;

  String get formattedAvailableBalance;
  String get formattedAdditionalBalance;
  String get formattedUnAvailableBalance => '';
  String get formattedSecondAvailableBalance => '';
  String get formattedSecondAdditionalBalance => '';
  String get formattedFullAvailableBalance => formattedAvailableBalance;
  String get formattedSelectedBalance => '';
}
