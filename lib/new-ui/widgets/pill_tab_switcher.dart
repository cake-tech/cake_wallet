import "package:flutter/material.dart";

class PillTabSwitcher extends StatelessWidget {
  const PillTabSwitcher({
    required this.tabs,
    required this.onTabChange,
    required this.selectedTab,
    this.expand = false,
    super.key,
  });

  final List<String> tabs;
  final void Function(int index) onTabChange;
  final int selectedTab;
  final bool expand;

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeOutCubic;
  static const _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pillShape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(999));
    final indicatorX = tabs.length > 1 ? -1 + 2 * selectedTab / (tabs.length - 1) : 0.0;

    final content = Stack(
      children: [
        Positioned.fill(
          child: AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: Alignment(indicatorX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: pillShape,
                  color: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (int index = 0; index < tabs.length; index++)
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    button: true,
                    selected: selectedTab == index,
                    inMutuallyExclusiveGroup: true,
                    child: GestureDetector(
                      key: ValueKey("pill_tab_switcher_${index}_key"),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabChange(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: AnimatedDefaultTextStyle(
                          duration: _duration,
                          curve: _curve,
                          style: DefaultTextStyle.of(context).style.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selectedTab == index
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                          child: Text(tabs[index], textAlign: TextAlign.center, maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: ShapeDecoration(shape: pillShape, color: colorScheme.surfaceContainer),
      child: IntrinsicWidth(
        child: expand ? content : IntrinsicWidth(child: content),
      ),
    );
  }
}
