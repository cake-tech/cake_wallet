enum SortBalanceBy {
  FiatBalance,
  Gross,
  Alphabetical;

  @override
  String toString() {
    switch (this) {
      case SortBalanceBy.FiatBalance:
        return "S.current.fiat_balance";
      case SortBalanceBy.Gross:
        return "S.current.gross";
      case SortBalanceBy.Alphabetical:
        return "S.current.alphabetical";
    }
  }
}