import 'package:cake_wallet/src/stores/action_list/action_list_item.dart';

class DateSectionItem extends ActionListItem {
  DateSectionItem(this.date);
  
  @override
  final DateTime date;
}