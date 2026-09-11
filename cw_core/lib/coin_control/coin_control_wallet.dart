import "package:cw_core/balance.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:cw_core/wallet_base.dart";

mixin CoinControlWallet<BalanceType extends Balance, HistoryType extends TransactionHistoryBase,
        TransactionType extends TransactionInfo>
    on WalletBase<BalanceType, HistoryType, TransactionType> {
  List<Unspent> get unspents;

  Future<void> refreshUnspents();

  FrozenCoinsStore get frozenCoinsStore => FrozenCoinsStore.instance;

  Future<Set<String>> frozenIds() => frozenCoinsStore.frozenIds(id);

  Future<void> setFrozen(String coinId, bool frozen) =>
      frozenCoinsStore.setFrozen(id, coinId, frozen);

  bool allowsCoinType(Unspent coin, UnspentCoinType coinType) => true;

  Future<List<Unspent>> spendableCoins(
     {CoinSelection selection = const AllCoinSelection(),
    UnspentCoinType coinType = UnspentCoinType.any,
  }) async {
    final frozen = await frozenIds();

    return unspents
        .where(
          (coin) =>
              !frozen.contains(coin.id) && selection.allows(coin) && allowsCoinType(coin, coinType),
        )
        .toList();
  }

  Future<int> frozenBalance() async {
    final frozen = await frozenIds();
    return unspents
        .where((coin) => frozen.contains(coin.id))
        .fold<int>(0, (sum, coin) => sum + coin.value);
  }


  Uri? coinControlUrl(String txId) => null;

}
