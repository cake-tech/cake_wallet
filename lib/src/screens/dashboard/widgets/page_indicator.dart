import 'dart:math' as math;
import 'dart:ui';
import 'package:cake_wallet/entities/page_indicator_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';

class PageIndicator extends StatefulWidget {
  const PageIndicator({
    super.key,
    required this.controller,
    required this.dashboardViewModel,
  });

  final PageController controller;
  final DashboardViewModel dashboardViewModel;

  @override
  State<PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  static const barHeight = 37.0;
  static const iconWidth = 16.0;
  static const iconHeight = 16.0;
  static const iconSpacing = 5.0;
  static const barHorizontalPadding = 4.0;
  static const pillHorizontalPadding = 8.0;
  static const edgePadding = 5.0;
  static const barBorderRadius = 50.0;
  static const pillBorderRadius = 50.0;
  static const pageSwitchDuration = Duration(milliseconds: 300);
  static const pillMoveDuration = Duration(milliseconds: 300);
  static const pillResizeDuration = Duration(milliseconds: 200);
  static const textStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  late int selectedIndex;
  late final VoidCallback _pageListener;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.controller.initialPage;

    _pageListener = () {
      final page = widget.controller.page;
      if (page == null) return;

      final rounded = page.round();
      if (rounded != selectedIndex && mounted) {
        setState(() {
          selectedIndex = rounded;
        });
      }
    };

    widget.controller.addListener(_pageListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_pageListener);
    super.dispose();
  }

  void _onItemTap(int index) {
    if (index == selectedIndex) return;
    widget.controller.animateToPage(
      index,
      duration: pageSwitchDuration,
      curve: Curves.easeOutCubic,
    );
  }

  double _estimateItemWidthForAction(
      BuildContext context, PageIndicatorActions action,
      {Color? color}) {
    final text = action.name(context);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle.copyWith(color: color)),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.of(context).textScaler,
    )..layout();
    return iconWidth +
        iconSpacing +
        textPainter.width +
        pillHorizontalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {

    final visibleActions = PageIndicatorActions.all.where((action) {
      return action.isEnabled?.call(widget.dashboardViewModel) ?? true;
    }).toList();

    // Don't show indicator if less than 2 actions
    if (visibleActions.length < 2) return const SizedBox.shrink();

    selectedIndex = selectedIndex.clamp(0, visibleActions.length - 1);

    // Theme setup
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceContainer.withAlpha(122);
    final pillColor = theme.colorScheme.onSurface.withAlpha(30);
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.primary;

    // Size calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final pillWidth = _estimateItemWidthForAction(
      context,
      visibleActions[selectedIndex],
      color: activeColor,
    );

    final actionWidths = [
      for (final action in visibleActions)
        _estimateItemWidthForAction(context, action, color: inactiveColor)
    ];

    final totalItemsWidth =
        actionWidths.fold(0.0, (sum, width) => sum + width) +
            barHorizontalPadding * 2;

    final barWidth = math.min(totalItemsWidth, screenWidth * 0.95);

    final count = visibleActions.length;
    final firstLeft = edgePadding;
    final secondLeft =
        barWidth - (isRTL ? actionWidths.first : actionWidths[1]) - edgePadding;

    final List<double> positions;

    if (count == 2) {
      positions = [firstLeft, secondLeft];
    } else {
      final lastLeft = barWidth -
          (isRTL ? actionWidths.first : actionWidths.last) -
          edgePadding;

      final centerLeft = (isRTL
          ? actionWidths.last + edgePadding
          : actionWidths.first + edgePadding);

      positions = [firstLeft, centerLeft, lastLeft];
    }

    final left =
        (isRTL ? positions.reversed.toList() : positions)[selectedIndex];
    final currentAction = visibleActions[selectedIndex];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 10),
        child: Container(
          width: barWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barBorderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(barBorderRadius),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedPill(
                        left: left,
                        pillColor: pillColor,
                        currentAction: currentAction,
                        pillIconHeight: iconHeight,
                        pillIconWidth: iconWidth,
                        pillIconSpacing: iconSpacing,
                        pillBorderRadius: pillBorderRadius,
                        contentColor: activeColor,
                        estimateWidthForAction: pillWidth,
                        pillTextStyle: textStyle,
                        pillMoveDuration: pillMoveDuration,
                        pillResizeDuration: pillResizeDuration,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: barHorizontalPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (int i = 0; i < visibleActions.length; i++)
                              Semantics(
                                button: true,
                                label: visibleActions[i].name(context),
                                value: i == selectedIndex ? 'Selected' : null,
                                hint: 'Double tap to open ${visibleActions[i].name(context)} page',
                                onTap: () => _onItemTap(i),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _onItemTap(i),
                                  child: Container(
                                    height: barHeight,
                                    width: i == selectedIndex
                                        ? pillWidth
                                        : _estimateItemWidthForAction(
                                            context, visibleActions[i]),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TweenAnimationBuilder<Color?>(
                                          duration: const Duration(
                                              milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          tween: ColorTween(
                                            begin: inactiveColor,
                                            end: i == selectedIndex
                                                ? activeColor
                                                : inactiveColor,
                                          ),
                                          builder: (context, color, _) =>
                                              SvgPicture.asset(
                                            visibleActions[i].image,
                                            width: iconWidth,
                                            height: iconHeight,
                                            colorFilter: ColorFilter.mode(
                                                color!, BlendMode.srcIn),
                                          ),
                                        ),
                                        SizedBox(width: iconSpacing),
                                        TweenAnimationBuilder<Color?>(
                                          duration: const Duration(
                                              milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          tween: ColorTween(
                                            begin: inactiveColor,
                                            end: i == selectedIndex
                                                ? activeColor
                                                : inactiveColor,
                                          ),
                                          builder: (context, color, _) =>
                                              Text(
                                            visibleActions[i].name(context),
                                            style: textStyle.copyWith(
                                                color: color),
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedPill extends StatelessWidget {
  const AnimatedPill({
    super.key,
    required this.left,
    required this.pillColor,
    required this.contentColor,
    required this.pillIconHeight,
    required this.pillIconWidth,
    required this.pillBorderRadius,
    required this.currentAction,
    required this.estimateWidthForAction,
    required this.pillIconSpacing,
    required this.pillTextStyle,
    required this.pillMoveDuration,
    required this.pillResizeDuration,
  });

  final double left;
  final Color pillColor;
  final Color contentColor;
  final double pillIconHeight;
  final double pillIconWidth;
  final double pillBorderRadius;
  final PageIndicatorActions currentAction;
  final double estimateWidthForAction;
  final double pillIconSpacing;
  final TextStyle pillTextStyle;
  final Duration pillMoveDuration;
  final Duration pillResizeDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: pillMoveDuration,
      curve: Curves.easeOutCubic,
      left: left,
      top: 4,
      bottom: 4,
      child: AnimatedContainer(
        duration: pillResizeDuration,
        curve: Curves.easeOutCubic,
        width: estimateWidthForAction,
        decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(pillBorderRadius)),
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
      ),
    );
  }
}
