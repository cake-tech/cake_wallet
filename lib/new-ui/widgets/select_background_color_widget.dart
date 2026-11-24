import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";

class SelectBackgroundColorWidget extends StatelessWidget {
  const SelectBackgroundColorWidget({
    required this.colors,
    required this.selectedIndex,
    required this.onColorSelected,
    super.key,
    this.title,
    this.firstIsEmpty = false,
  });

  final List<Gradient> colors;
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;
  final String? title;

  /// no background.
  final bool firstIsEmpty;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? S.of(context).color,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < colors.length; index++)
                      _Swatch(
                        isSelected: index == selectedIndex,
                        onTap: () => onColorSelected(index),
                        decoration: firstIsEmpty && index == 0
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              )
                            : BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: colors[index],
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.isSelected,
    required this.onTap,
    required this.decoration,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(999999999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999999999),
          onTap: onTap,
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1 : 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 0.8 : 1,
                child: Container(width: 32, height: 32, decoration: decoration),
              ),
            ],
          ),
        ),
      );
}
