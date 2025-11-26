import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:flutter/material.dart';

class ListItemToggleWidget extends StatefulWidget {
  const ListItemToggleWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  State<ListItemToggleWidget> createState() => _ListItemToggleWidgetState();
}

class _ListItemToggleWidgetState extends State<ListItemToggleWidget> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final radius = BorderRadius.vertical(
      top: Radius.circular(widget.isFirstInSection ? 16 : 0),
      bottom: Radius.circular(widget.isLastInSection ? 16 : 0),
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: widget.isLastInSection
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label),
            StandardSwitch(
              value: _value,
              onTapped: () {
                final newValue = !_value;
                setState(() => _value = newValue);
                widget.onChanged(newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}
