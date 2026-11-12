import "package:flutter/material.dart";

class PillSegmentedControl<T> extends StatelessWidget {
  const PillSegmentedControl({
    required this.items,
    required this.selectedItem,
    required this.labelFor,
    required this.onSelected,
    super.key,
  });

  final List<T> items;
  final T selectedItem;
  final String Function(T item) labelFor;
  final ValueChanged<T> onSelected;

  static const _switchDuration = Duration(milliseconds: 250);
  static const _dividerWidth = 0.6;

  bool _hasDividerBefore(int index, int selectedIndex) =>
      index > 0 && index != selectedIndex && index - 1 != selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium!;
    final selectedIndex = items.indexOf(selectedItem);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainer,
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.surfaceContainerHighest, width: _dividerWidth),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;

          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: _switchDuration,
                  curve: Curves.easeInOut,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colorScheme.primary,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (index, item) in items.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: index == selectedIndex,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelected(item),
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: _hasDividerBefore(index, selectedIndex)
                                ? BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: colorScheme.onSurface,
                                        width: _dividerWidth,
                                      ),
                                    ),
                                  )
                                : null,
                            child: AnimatedDefaultTextStyle(
                              duration: _switchDuration,
                              style: labelStyle.copyWith(
                                color: index == selectedIndex
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              child: Text(labelFor(item)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
