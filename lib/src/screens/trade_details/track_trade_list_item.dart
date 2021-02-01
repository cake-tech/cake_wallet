import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:flutter/material.dart';

class TrackTradeListItem extends StandartListRow {
  TrackTradeListItem({String title, String value, this.onTap})
      : super(title: title, value: value);
  final Function() onTap;
}
