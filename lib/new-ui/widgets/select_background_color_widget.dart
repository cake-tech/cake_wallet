import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";

class SelectBackgroundColorWidget extends StatelessWidget {
  const SelectBackgroundColorWidget({
    required this.colors,
    required this.selectedIndex,
    required this.onColorSelected,
    super.key,
    this.title,
    this.isToggleable = false,
    this.isEnabled = true,
    this.onToggleChanged,
  }) : assert(
          !isToggleable || onToggleChanged != null,
          "onToggleChanged is required when isToggleable is true",
        );

  final List<Gradient> colors;
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;
  final String? title;
  final bool isToggleable;
  final bool isEnabled;
  final ValueChanged<bool>? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    final showColors = !isToggleable || isEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title ?? S.of(context).color)),
                if (isToggleable)
                  Switch(
                    value: isEnabled,
                    onChanged: onToggleChanged,
                  ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
              crossFadeState: showColors ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              secondChild: const SizedBox(width: double.infinity, height: 0),
              firstChild: SizedBox(
                width: double.infinity,
                child: Wrap(
                  direction: Axis.horizontal,
                  spacing: 4,
                  runSpacing: 8,
                  children: List.generate(colors.length, (index) {
                    final isSelected = index == selectedIndex;
                    return Material(
                      borderRadius: BorderRadius.circular(999999999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999999999),
                        onTap: () => onColorSelected(index),
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSelected ? 1 : 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99999999),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 0.8 : 1,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99999999),
                                  gradient: colors[index],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
