import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/material.dart';

class StandardPickerList<T> extends StatefulWidget {
  StandardPickerList({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.displayItem,
    required this.onSliderChanged,
    required this.onItemSelected,
    required this.selectedIdx,
    required this.customItemIndex,
    required this.customValue,
    this.maxValue,
  }) : super(key: key);

  final String title;
  final List<T> items;
  final int customItemIndex;
  final String Function(T item, double sliderValue) displayItem;
  final Function(double) onSliderChanged;
  final Function(T item, double sliderValue) onItemSelected;
  final String value;
  final int selectedIdx;
  final double customValue;
  final double? maxValue;

  @override
  _StandardPickerListState<T> createState() => _StandardPickerListState<T>();
}

class _StandardPickerListState<T> extends State<StandardPickerList<T>> {
  late String value;
  late int selectedIdx;
  late double customValue;

  @override
  void initState() {
    super.initState();

    value = widget.value;
    selectedIdx = widget.selectedIdx;
    customValue = widget.customValue;
  }

  @override
  Widget build(BuildContext context) {
    String adaptedDisplayItem(T item) => widget.displayItem(item, customValue);
    String adaptedOnItemSelected(T item) => widget.onItemSelected(item, customValue).toString();

    return Column(
      children: [
        ListRow(title: '${widget.title}:', value: value),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
          child: Picker(
            items: widget.items,
            displayItem: adaptedDisplayItem,
            selectedAtIndex: selectedIdx,
            customItemIndex: widget.customItemIndex,
            maxValue: widget.maxValue,
            headerEnabled: false,
            closeOnItemSelected: false,
            mainAxisAlignment: MainAxisAlignment.center,
            sliderValue: customValue,
            isWrapped: false,
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            onSliderChanged: (newValue) {
              setState(() => customValue = newValue);
              value = widget.onSliderChanged(newValue).toString();
            },
            onItemSelected: (T item) {
              setState(() => selectedIdx = widget.items.indexOf(item));
              value = adaptedOnItemSelected(item);
            },
          ),
        ),
      ],
    );
  }
}
