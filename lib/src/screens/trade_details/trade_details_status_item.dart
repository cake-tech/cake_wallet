import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

class DetailsListStatusItem extends StandartListItem {
  DetailsListStatusItem(
      {required String title, required String value, this.status})
      : super(title: title, value: value);

  final String? status; // waiting, action required, created, fetching, finished, success
}
