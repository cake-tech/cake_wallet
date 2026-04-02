import 'package:cake_wallet/new-ui/viewmodels/charts/util/chart_range.dart';
import 'package:flutter/material.dart';

class ChartRangeSelector extends StatelessWidget {
  const ChartRangeSelector({super.key, required this.selectedRange, required this.onRangeSelected});

  final ChartRange selectedRange;
  final Function(ChartRange) onRangeSelected;

  static const double optionSize = 36;
  static const double optionPadding = 24;
  static const Duration switchDuration = Duration(milliseconds: 250);

  double pillPosition(int selectedIndex) => selectedIndex * (optionSize + optionPadding);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ChartRange.ranges.indexOf(selectedRange);

    return Stack(
      children: [
        AnimatedPositioned(
            curve: Curves.easeOutCubic,
            left: pillPosition(selectedIndex),
            child: Container(
              height: optionSize,
              width: optionSize,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
                  borderRadius: BorderRadius.circular(999999)),
            ),
            duration: switchDuration),
        Row(
          spacing: optionPadding,
          children: ChartRange.ranges.map((item) {
            final selected = selectedRange == item;
            return GestureDetector(
              onTap: ()=>onRangeSelected(item),
              child: Container(
                width: optionSize,
                height: optionSize,
                child: AnimatedDefaultTextStyle(
                    duration: switchDuration,
                    style: TextStyle(
                        fontWeight: selected ? FontWeight.w400 : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    child: Center(child: Text(item.displayText))),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}