import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeDetailsListCardItem extends StandartListItem {
  TradeDetailsListCardItem(
      {String title,
      String value,
      this.id,
      this.createdAt,
      this.pair,
      this.onTap})
      : super(title: title, value: value);

  factory TradeDetailsListCardItem.tradeDetails(
      {@required String id,
      @required String createdAt,
      @required CryptoCurrency from,
      @required CryptoCurrency to,
      @required Function onTap}) {
    return TradeDetailsListCardItem(
        id: '${S.current.trade_details_id}  ${formatAsText(id)}',
        createdAt: formatAsText(createdAt),
        pair: '${formatAsText(from)} → ${formatAsText(to)}',
        onTap: onTap);
  }

  final String id;
  final String createdAt;
  final String pair;
  final Function onTap;

  static String formatAsText<T>(T value) => value?.toString() ?? '';
}
