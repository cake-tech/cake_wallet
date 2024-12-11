import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

class TradeDetailsListCardItem extends StandartListItem {
  TradeDetailsListCardItem(
      {required this.id,
      required this.createdAt,
      required this.pair,
      required this.onTap,
      this.extraId})
      : super(title: '', value: '');

  factory TradeDetailsListCardItem.tradeDetails(
      {required String id,
      required String createdAt,
      required CryptoCurrency from,
      required CryptoCurrency to,
      required void Function(BuildContext) onTap,
      String? extraId}) {


      final extraIdTitle = from == CryptoCurrency.xrp
          ? S.current.destination_tag
          : from == CryptoCurrency.xlm
          ? S.current.memo
          : S.current.extra_id;

    return TradeDetailsListCardItem(
        id: '${S.current.trade_details_id}  ${formatAsText(id)}',
        extraId: extraId != null ? '$extraIdTitle  $extraId' : null,
        createdAt: formatAsText(createdAt),
        pair: '${formatAsText(from)} → ${formatAsText(to)}',
        onTap: onTap);
  }

  final String id;
  final String createdAt;
  final String pair;
  final String? extraId;
  final void Function(BuildContext) onTap;

  static String formatAsText<T>(T value) => value?.toString() ?? '';
}
