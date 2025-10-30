import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cake_wallet/entities/new_main_actions.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';

class NewMainNavBar extends StatefulWidget {
  const NewMainNavBar({
    super.key,
    required this.dashboardViewModel,
    this.initialIndex = 0,
  });

  final DashboardViewModel dashboardViewModel;
  final int initialIndex;

  @override
  State<NewMainNavBar> createState() => _NewMainNavBarState();
}

class _NewMainNavBarState extends State<NewMainNavBar> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _onItemTap(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
    NewMainActions.all[index].onTap.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withAlpha(85);
    final pillColor = theme.colorScheme.onSurfaceVariant.withAlpha(85);
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.primary;

    final visibleActions = NewMainActions.all
        .where(
            (action) => action.canShow?.call(widget.dashboardViewModel) ?? true)
        .toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double outerPadding = 12;
                    const double inset = 10.0;
                    final totalWidth = constraints.maxWidth - outerPadding * 2;
                    final baseItemWidth = totalWidth / visibleActions.length;
                    final pillWidth = baseItemWidth * 1.25;
                    final leftPosition = (baseItemWidth * selectedIndex) +
                        (baseItemWidth - pillWidth) / 2;
                    final clampedLeft = leftPosition.clamp(
                      0.0,
                      totalWidth - pillWidth,
                    );

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: outerPadding),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            left: clampedLeft,
                            top: inset,
                            bottom: inset,
                            width: pillWidth,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: pillColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: visibleActions.map((action) {
                                final index = visibleActions.indexOf(action);
                                final isSelected = index == selectedIndex;
                                final contentShift = (index == 0 && isSelected) ? 6.0 : 0.0;

                                return Flexible(
                                  fit: FlexFit.tight,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () => _onItemTap(index),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 450),
                                      curve: Curves.easeOutCubic,
                                      alignment: Alignment.center,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: AnimatedPadding(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeOutCubic,
                                          padding: EdgeInsets.only(left: contentShift),
                                          child: IntrinsicWidth(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                              AnimatedScale(
                                                duration: const Duration(
                                                    milliseconds: 450),
                                                curve: Curves.easeOutExpo,
                                                scale: isSelected ? 0.9 : 1.0,
                                                child: SvgPicture.asset(
                                                  action.image,
                                                  width: 26,
                                                  height: 26,
                                                  colorFilter: ColorFilter.mode(
                                                    isSelected
                                                        ? activeColor
                                                        : inactiveColor,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 500),
                                                switchInCurve:
                                                    Curves.easeOutCubic,
                                                switchOutCurve:
                                                    Curves.easeInOutCubic,
                                                transitionBuilder:
                                                    (child, animation) =>
                                                        FadeTransition(
                                                  opacity: animation,
                                                  child: SizeTransition(
                                                    sizeFactor: animation,
                                                    axis: Axis.horizontal,
                                                    child: child,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? Padding(
                                                        key: ValueKey(index),
                                                  padding: const EdgeInsets.only(left: 8, right: 10),
                                                        child: Center(
                                                          child: Text(
                                                            action
                                                                .name(context),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  activeColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 16,
                                                              height: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ));
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
