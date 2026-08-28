import 'package:cw_core/history_source.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/app_store.dart';
import "package:cw_core/action_list_item.dart";
import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/transaction_direction.dart';
import "package:cw_core/transaction_info.dart";

class TransactionFilterStore extends HistoryFilters {
  TransactionFilterStore(this._appStore)
      : displayIncoming = true,
        displayOutgoing = true,
        displaySilentPayments = true;

  final AppStore _appStore;

  bool displayIncoming;

  bool displayOutgoing;

  bool displaySilentPayments;

  DateTime? startDate;

  DateTime? endDate;

  bool get displayAll => displayIncoming && displayOutgoing && displaySilentPayments;

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

  void toggleIncoming() {
    displayIncoming = !displayIncoming;
  }

  void toggleOutgoing() {
    displayOutgoing = !displayOutgoing;
  }

  void toggleSilentPayments() {
    displaySilentPayments = !displaySilentPayments;
  }

  void changeStartDate(DateTime date) => startDate = date;

  void changeEndDate(DateTime date) => endDate = date;

  static const _outgoing = "send";
  static const _incoming = "receive";
  static const _silentPayments = "silent_payments";

  @override
  List<HistoryFilter> get filters => [
        HistoryFilter(key: _outgoing, caption: _outgoing, value: displayOutgoing),
        HistoryFilter(key: _incoming, caption: _incoming, value: displayIncoming),
        if (_appStore.wallet?.type == WalletType.bitcoin)
          HistoryFilter(
            key: _silentPayments,
            caption: _silentPayments,
            value: displaySilentPayments,
          ),
      ];

  @override
  void toggleFilter(HistoryFilter filter) {
    switch (filter.key) {
      case _outgoing:
        toggleOutgoing();
      case _incoming:
        toggleIncoming();
      case _silentPayments:
        toggleSilentPayments();
    }
  }

  @override
  void setAllFilters({required bool value}) {
    displayOutgoing = value;
    displayIncoming = value;
    displaySilentPayments = value;
  }

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


}
