import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';

class DateSectionItem extends ActionListItem {
  DateSectionItem(this.date, {required super.key});
  
  @override
  final DateTime date;
}