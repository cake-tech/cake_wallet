import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:flutter/material.dart';

class CakePayDetailsListCardItem extends StandartListItem {
  CakePayDetailsListCardItem({
    required String title,
    required String value,
    required this.id,
    required this.createdAt,
    this.price,
    this.quantity,
    required this.from,
    required this.to,
    required this.onTap,
    required this.cards,
  }) : super(title: title, value: value);

  final String id;
  final String createdAt;
  final String? price;
  final String? quantity;
  final String from;
  final String to;
  final void Function(BuildContext) onTap;
  final List<OrderCard> cards;
}
