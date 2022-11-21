import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

class TrackTradeListItem extends StandartListItem {
  TrackTradeListItem({
    required String title,
    required String value,
    required this.onTap})
      : super(title: title, value: value);
  final Function() onTap;
}
