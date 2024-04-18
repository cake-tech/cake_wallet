import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class StandardPickerListItem<T> extends TransactionDetailsListItem {
  StandardPickerListItem(
      {required String title,
      required String value,
      required this.items,
      required this.displayItem,
      required this.onSliderChanged,
      required this.onItemSelected,
      required this.selectedIdx,
      required this.customItemIndex,
      this.maxValue,
      required this.customValue})
      : super(title: title, value: value);

  final List<T> items;
  final String Function(T item, double sliderValue) displayItem;
  final Function(double) onSliderChanged;
  final Function(T) onItemSelected;
  final int selectedIdx;
  final double? maxValue;
  final int customItemIndex;
  double customValue;
}
