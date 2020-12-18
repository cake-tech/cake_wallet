import 'package:cake_wallet/entities/balance_display_mode.dart';

abstract class Balance {
  const Balance(this.availableModes);

  final List<BalanceDisplayMode> availableModes;

  String formattedBalance(BalanceDisplayMode mode);
}
