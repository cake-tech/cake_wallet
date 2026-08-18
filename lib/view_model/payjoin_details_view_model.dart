import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'payjoin_details_view_model.g.dart';

class PayjoinDetailsViewModel = PayjoinDetailsViewModelBase with _$PayjoinDetailsViewModel;

abstract class PayjoinDetailsViewModelBase with Store {
  PayjoinDetailsViewModelBase(
    this.payjoinSessionId,
    this.transactionInfo, {
    required this.payjoinSessionSource,
    required this.themeStore,
  })  : items = ObservableList<TransactionDetailsListItem>(),
        payjoinSession = payjoinSessionSource.get(payjoinSessionId)! {
    if (transactionInfo != null) {
      _transactionDetailsViewModel =
          getIt.get<TransactionDetailsViewModel>(param1: [transactionInfo, false]);
      final hasRecipient = _transactionDetailsViewModel!.items.any((i) => i is AddressListItem);
      if (!hasRecipient && payjoinSession.recipientAddress != null) {
        _transactionDetailsViewModel!.items.insert(
          _recipientInsertIndex(_transactionDetailsViewModel!.items),
          AddressListItem(
            title: S.current.transaction_details_recipient_address,
            value: payjoinSession.recipientAddress!,
            key: const ValueKey('standard_list_item_transaction_details_recipient_address_key'),
          ),
        );
      }
    }
    listener = payjoinSessionSource.watch().listen((e) {
      if (e.key == payjoinSessionId) _updateItems();
    });
    _updateItems();
  }

  final Box<PayjoinSession> payjoinSessionSource;
  final ThemeStore themeStore;
  final String payjoinSessionId;
  final TransactionInfo? transactionInfo;

  TransactionDetailsViewModel? _transactionDetailsViewModel;
  TransactionDetailsViewModel? get transactionDetailsViewModel => _transactionDetailsViewModel;

  @observable
  late PayjoinSession payjoinSession;

  final ObservableList<TransactionDetailsListItem> items;

  late final StreamSubscription<BoxEvent> listener;

  Timer? timer;

  @action
  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();
    items.clear();
    items.addAll([
      DetailsListStatusItem(
        title: S.current.status,
        value: _getStatusString(),
        status: payjoinSession.status,
      ),
      TradeDetailsListCardItem(
        id: payjoinSession.isSenderSession ? S.current.sending : S.current.receiving,
        createdAt: dateFormat.format(payjoinSession.inProgressSince!).toString(),
        pair:
            "${bitcoin!.formatterBitcoinAmountToString(amount: payjoinSession.amount.toInt())} BTC",
        onTap: (_) {},
      ),
      if (payjoinSession.error?.isNotEmpty == true)
        StandartListItem(
          title: S.current.error,
          value: payjoinSession.error!,
        ),
    ]);

    if (_transactionDetailsViewModel != null) {
      items.addAll(_transactionDetailsViewModel!.items);
    }

    if (payjoinSession.txId?.isNotEmpty == true) {
      items.add(BlockExplorerListItem(
        title: '${S.current.view_transaction_on}mempool.cakewallet.com',
        value: '${S.current.view_transaction_on}mempool.space',
        onTap: () async {
          try {
            final uri = Uri.parse('https://mempool.cakewallet.com/tx/${payjoinSession.txId!}');
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {}
        },
        key: ValueKey('block_explorer_list_item_wallet_type_key'),
      ));
    }
  }

  @action
  void cancel() {
    final wallet = getIt.get<AppStore>().wallet;
    if (wallet == null) return;
    bitcoin!.cancelPayjoinSession(wallet, payjoinSessionId);
  }

  @action
  Future<void> fallbackBroadcast() async {
    if (payjoinSession.originalPsbt == null) return;
    final wallet = getIt.get<AppStore>().wallet;
    if (wallet == null) return;
    await bitcoin!.fallbackBroadcastPayjoin(wallet, payjoinSessionId);
  }

  bool get canCancel =>
      payjoinSession.status == PayjoinSessionStatus.inProgress.name ||
      payjoinSession.status == PayjoinSessionStatus.waiting.name ||
      payjoinSession.status == PayjoinSessionStatus.created.name;

  bool get canFallback =>
      payjoinSession.originalPsbt?.isNotEmpty == true &&
      !payjoinSession.usedFallback &&
      (payjoinSession.status == PayjoinSessionStatus.inProgress.name ||
          payjoinSession.status == PayjoinSessionStatus.unrecoverable.name);

  int _recipientInsertIndex(List<TransactionDetailsListItem> items) {
    if (payjoinSession.isSenderSession) {
      return items.length;
    }
    const txIdKey = 'standard_list_item_transaction_details_id_key';
    final txIdIdx = items.indexWhere(
      (i) => (i.key as ValueKey?)?.value == txIdKey,
    );
    return txIdIdx == -1 ? items.length : txIdIdx;
  }

  String _getStatusString() {
    switch (payjoinSession.status) {
      case 'success':
        if (transactionInfo?.isPending == false) return S.current.successful;
        return S.current.payjoin_request_awaiting_tx;
      case 'inProgress':
        return S.current.payjoin_request_in_progress;
      case 'waiting':
        return S.current.payjoin_request_awaiting_tx;
      case 'unrecoverable':
        if (payjoinSession.error == 'Cancelled') return S.current.cancelled;
        return S.current.error;
      default:
        return payjoinSession.status;
    }
  }
}
