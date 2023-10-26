import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

class TradeProviderUnsupportedItem extends StandartListItem {
  TradeProviderUnsupportedItem({required String error}) : super(title: '', value: error);
}
