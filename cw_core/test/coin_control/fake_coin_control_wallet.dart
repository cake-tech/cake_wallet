import "package:cw_core/balance.dart";
import "package:cw_core/coin_control/coin_control_wallet.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/node.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";

typedef _History = TransactionHistoryBase<TransactionInfo>;

/// A wallet double for the coin control mixin.
///
/// The mixin is declared `on WalletBase`, so a double has to be one. Only the
/// members coin control reaches are implemented; the rest throw, so a test that
/// starts depending on one fails loudly instead of quietly reading a stub.
class FakeCoinControlWallet extends WalletBase<Balance, _History, TransactionInfo>
    with CoinControlWallet<Balance, _History, TransactionInfo> {
  FakeCoinControlWallet({
    required String id,
    required this.unspents,
    required this.frozenCoinsStore,
    this.coinTypeOf,
    WalletType type = WalletType.bitcoin,
  }) : super(
          WalletInfo.external(
            id: id,
            name: id,
            type: type,
            isRecovery: false,
            restoreHeight: 0,
            date: DateTime(2026),
            dirPath: "",
            path: "",
            address: "",
          ),
          DerivationInfo(),
        );

  @override
  List<Unspent> unspents;

  @override
  final FrozenCoinsStore frozenCoinsStore;

  /// Stands in for a chain that has more than one kind of output.
  final UnspentCoinType Function(Unspent coin)? coinTypeOf;

  int refreshCount = 0;

  @override
  Future<void> refreshUnspents() async => refreshCount++;

  @override
  bool allowsCoinType(Unspent coin, UnspentCoinType coinType) {
    if (coinTypeOf == null || coinType == UnspentCoinType.any) {
      return true;
    }
    return coinTypeOf!(coin) == coinType;
  }

  // WalletBase's remaining surface, none of which coin control touches.

  @override
  ObservableMap<CryptoCurrency, Balance> get balance => throw UnimplementedError();

  @override
  SyncStatus get syncStatus => throw UnimplementedError();

  @override
  set syncStatus(SyncStatus status) => throw UnimplementedError();

  @override
  String? get seed => throw UnimplementedError();

  @override
  Object get keys => throw UnimplementedError();

  @override
  WalletAddresses get walletAddresses => throw UnimplementedError();

  @override
  String get password => throw UnimplementedError();

  @override
  Future<void> connectToNode({required Node node}) => throw UnimplementedError();

  @override
  Future<void> startSync() => throw UnimplementedError();

  @override
  Future<PendingTransaction> createTransaction(Object credentials) => throw UnimplementedError();

  @override
  Future<int> calculateEstimatedFee(
    TransactionPriority priority,
    int? amount, {
    CoinSelection selection = const AllCoinSelection(),
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, TransactionInfo>> fetchTransactions() => throw UnimplementedError();

  @override
  Future<void> save() => throw UnimplementedError();

  @override
  Future<void> rescan({required int height}) => throw UnimplementedError();

  @override
  Future<void> close({bool shouldCleanup = false}) => throw UnimplementedError();

  @override
  Future<void> changePassword(String password) => throw UnimplementedError();

  @override
  Future<void>? updateBalance() => throw UnimplementedError();

  @override
  Future<String> signMessage(String message, {String? address}) => throw UnimplementedError();

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) =>
      throw UnimplementedError();

  @override
  Future<bool> checkNodeHealth() => throw UnimplementedError();
}
