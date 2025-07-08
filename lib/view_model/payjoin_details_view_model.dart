import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'payjoin_details_view_model.g.dart';

class PayjoinDetailsViewModel = PayjoinDetailsViewModelBase
    with _$PayjoinDetailsViewModel;

abstract class PayjoinDetailsViewModelBase with Store {
  PayjoinDetailsViewModelBase(
    this.payjoinSessionId,
    this.transactionInfo, {
    required this.payjoinSessionSource,
    required this.themeStore,
  })  : items = ObservableList<TransactionDetailsListItem>(),
        payjoinSession = payjoinSessionSource.get(payjoinSessionId)! {
    listener = payjoinSessionSource.watch().listen((e) {
      if (e.key == payjoinSessionId) _updateItems();
    });
    _updateItems();
  }

  final Box<PayjoinSession> payjoinSessionSource;
  final ThemeStore themeStore;
  final String payjoinSessionId;
  final TransactionInfo? transactionInfo;

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
        id: "${payjoinSession.isSenderSession ? S.current.outgoing : S.current.incoming} Payjoin",
        createdAt:
            dateFormat.format(payjoinSession.inProgressSince!).toString(),
        pair:
            '${bitcoin!.formatterBitcoinAmountToString(amount: payjoinSession.amount.toInt())} BTC',
        onTap: (_) {},
      ),
      if (payjoinSession.error?.isNotEmpty == true)
        StandartListItem(
          title: S.current.error,
          value: payjoinSession.error!,
        ),
      if (payjoinSession.txId?.isNotEmpty == true && transactionInfo != null) ...[
        StandartListItem(
          title: S.current.transaction_details_transaction_id,
          value: payjoinSession.txId!,
          key: ValueKey('standard_list_item_transaction_details_id_key'),
        ),
        BlockExplorerListItem(
          title: S.current.view_in_block_explorer,
          value: '${S.current.view_transaction_on}mempool.space',
          onTap: () async {
            try {
              final uri = Uri.parse('https://mempool.cakewallet.com/tx/${payjoinSession.txId!}');
              if (await canLaunchUrl(uri))
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {}
          },
          key: ValueKey('block_explorer_list_item_wallet_type_key'),
        )
      ]
    ]);

    if (transactionInfo != null) {
      items.addAll([
        StandartListItem(
          title: S.current.transaction_details_date,
          value: dateFormat.format(transactionInfo!.date),
          key: ValueKey('standard_list_item_transaction_details_date_key'),
        ),
        StandartListItem(
          title: S.current.confirmations,
          value: transactionInfo!.confirmations.toString(),
          key: ValueKey('standard_list_item_transaction_confirmations_key'),
        ),
        StandartListItem(
          title: S.current.transaction_details_height,
          value: '${transactionInfo!.height}',
          key: ValueKey('standard_list_item_transaction_details_height_key'),
        ),
        if (transactionInfo!.feeFormatted()?.isNotEmpty ?? false)
          StandartListItem(
            title: S.current.transaction_details_fee,
            value: transactionInfo!.feeFormatted()!,
            key: ValueKey('standard_list_item_transaction_details_fee_key'),
          ),
      ]);
    }
  }

  String _getStatusString() {
    switch (payjoinSession.status) {
      case 'success':
        if (transactionInfo?.isPending == false) return S.current.successful;
        return S.current.payjoin_request_awaiting_tx;
      case 'inProgress':
        return S.current.payjoin_request_in_progress;
      case 'unrecoverable':
        return S.current.error;
      default:
        return payjoinSession.status;
    }
  }
}
