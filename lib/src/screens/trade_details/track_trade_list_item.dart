import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

class TrackTradeListItem extends StandartListItem {
  TrackTradeListItem({String title, String value, this.onTap})
      : super(title: title, value: value);
  final Function() onTap;
}
