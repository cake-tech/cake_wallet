import "package:cw_core/unspent_transaction_output.dart";

abstract class CoinSelection {
  const CoinSelection();

  bool allows(Unspent coin);
}

class AllCoinSelection extends CoinSelection {
  const AllCoinSelection();

  @override
  bool allows(Unspent coin) => true;
}

class SpecificCoinSelection extends CoinSelection {
  SpecificCoinSelection(Iterable<String> ids) : ids = Set.unmodifiable(ids);

  final Set<String> ids;

  @override
  bool allows(Unspent coin) => ids.contains(coin.id);
}
