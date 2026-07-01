import 'package:cake_wallet/generated/i18n.dart';

enum SortBalanceBy {
  FiatBalance,
  GrossBalance,
  Alphabetical;

  @override
  String toString() {
    switch (this) {
      case SortBalanceBy.FiatBalance:
        return S.current.fiat_balance;
      case SortBalanceBy.GrossBalance:
        return S.current.gross_balance;
      case SortBalanceBy.Alphabetical:
        return S.current.alphabetical;
    }
  }
}