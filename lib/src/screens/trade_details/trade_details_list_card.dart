import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

class DetailsListCardItem extends StandartListItem {
  DetailsListCardItem(
      {String title, String value, this.id, this.create, this.pair, this.onTap})
      : super(title: title, value: value);
  final String id;
  final String create;
  final String pair;
  final Function onTap;
}
