import 'dart:async';

import 'package:cake_wallet/anonpay/anonpay_api.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher_string.dart';

part 'anonpay_details_view_model.g.dart';

class AnonpayDetailsViewModel = AnonpayDetailsViewModelBase with _$AnonpayDetailsViewModel;

abstract class AnonpayDetailsViewModelBase with Store {
  AnonpayDetailsViewModelBase(
      {required this.anonPayApi,
      required AnonpayInvoiceInfo anonpayInvoiceInfo,
      required this.settingsStore})
      : items = ObservableList<StandartListItem>(),
        invoiceDetail = anonpayInvoiceInfo {
    _updateItems();
    _updateInvoiceDetail();
    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateInvoiceDetail());
  }

  final AnonPayApi anonPayApi;
  final SettingsStore settingsStore;
  final AnonpayInvoiceInfo invoiceDetail;

  final ObservableList<StandartListItem> items;

  Timer? timer;

  @action
  Future<void> _updateInvoiceDetail() async {
    try {
      final data = await anonPayApi.paymentStatus(invoiceDetail.invoiceId);
      invoiceDetail.status = data.status;
      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();
    items.clear();
    items.addAll([
      DetailsListStatusItem(title: S.current.status, value: invoiceDetail.status),
      TradeDetailsListCardItem(
        id: invoiceDetail.invoiceId,
        createdAt: dateFormat.format(invoiceDetail.createdAt).toString(),
        pair: (invoiceDetail.fiatAmount != null)
            ? "→ ${invoiceDetail.fiatAmount} ${invoiceDetail.fiatEquiv ?? ''}"
            : '→ ${invoiceDetail.amountTo ?? ''} ${CryptoCurrency.fromFullName(invoiceDetail.coinTo).name.toUpperCase()}',
        onTap: (BuildContext context) {
          Clipboard.setData(ClipboardData(text: '${invoiceDetail.invoiceId}'));
          showBar<void>(context, S.of(context).copied_to_clipboard);
        },
      ),
      StandartListItem(title: S.current.trade_details_provider, value: invoiceDetail.provider)
    ]);

    items.add(TrackTradeListItem(
        title: 'Track',
        value: invoiceDetail.clearnetStatusUrl,
        onTap: () => launchUrlString(invoiceDetail.clearnetStatusUrl)));
  }
}
