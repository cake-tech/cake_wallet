import 'package:cw_core/history_source.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/app_store.dart';
import "package:cw_core/action_list_item.dart";
import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_direction.dart';
import "package:cw_core/transaction_info.dart";

part 'transaction_filter_store.g.dart';

class TransactionFilterStore = TransactionFilterStoreBase with _$TransactionFilterStore;

abstract class TransactionFilterStoreBase with Store implements HistoryFilters {
  TransactionFilterStoreBase(this._appStore)
      : displayIncoming = true,
        displayOutgoing = true,
        displaySilentPayments = true;

  final AppStore _appStore;

  @observable
  bool displayIncoming;

  @observable
  bool displayOutgoing;

  @observable
  bool displaySilentPayments;

  @observable
  DateTime? startDate;

  @observable
  DateTime? endDate;

  @computed
  bool get displayAll => displayIncoming && displayOutgoing && displaySilentPayments;

  @action
  void toggleAll() {
    if (displayAll) {
      displayOutgoing = false;
      displayIncoming = false;
      displaySilentPayments = false;
    } else {
      displayOutgoing = true;
      displayIncoming = true;
      displaySilentPayments = true;
    }
  }

  @action
  void toggleIncoming() {
    displayIncoming = !displayIncoming;
  }

  @action
  void toggleOutgoing() {
    displayOutgoing = !displayOutgoing;
  }

  @action
  void toggleSilentPayments() {
    displaySilentPayments = !displaySilentPayments;
  }

  @action
  void changeStartDate(DateTime date) => startDate = date;

  @action
  void changeEndDate(DateTime date) => endDate = date;

  /// Whether one item passes the wallet, account and user filters.
  ///
  /// Serves both the transaction and anonpay sources: the date range and
  /// direction toggles have always applied to both, and now the wallet and
  /// account scoping does too.
  @override
  bool relevant(HistoryListItem item) {
    if (!_inScope(item)) {
      return false;
    }

    if (startDate != null && endDate != null) {
      if (!(startDate!.isBefore(item.date) && endDate!.isAfter(item.date))) {
        return false;
      }
    }

    if (displayAll) {
      return true;
    }

    if (item is TransactionInfo) {
      final canShowSilentPayment = _appStore.wallet?.type == WalletType.bitcoin &&
          (bitcoin?.txIsReceivedSilentPayment(item) ?? false);

      return (displayOutgoing && item.direction == TransactionDirection.outgoing) ||
          (displayIncoming &&
              item.direction == TransactionDirection.incoming &&
              !canShowSilentPayment) ||
          (displaySilentPayments && canShowSilentPayment);
    }

    return displayIncoming;
  }

  /// Monero keeps every account's transactions in one history, so the account
  /// has to be filtered rather than the history split. Anonpay invoices carry
  /// their own wallet id.
  bool _inScope(HistoryListItem item) {
    final wallet = _appStore.wallet;

    if (item is TransactionInfo) {
      if (wallet == null || wallet.type != WalletType.monero) {
        return true;
      }
      return monero!.getTransactionInfoAccountId(item) == monero!.getCurrentAccount(wallet).id;
    }

    if (item is AnonpayInvoiceInfo) {
      return item.walletId == wallet?.id;
    }

    return false;
  }


  List<HistoryListItem> filtered({required List<HistoryListItem> transactions}) =>
      transactions.where(relevant).toList();
}
