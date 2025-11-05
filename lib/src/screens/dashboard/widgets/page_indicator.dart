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
  static const pillIconWidth = 16.0;
  static const pillIconHeight = 16.0;
  static const pillIconSpacing = 5.0;
  static const pillHorizontalPadding = 8.0;
  static const barBorderRadius = 50.0;
  static const pillBorderRadius = 50.0;
  static const barResizeDuration = Duration(milliseconds: 400);
  static const inactiveIconMoveDuration = Duration(milliseconds: 150);
  static const inactiveIconFadeDuration = Duration(milliseconds: 100);
  static const inactiveIconAppearDuration = Duration(milliseconds: 250);
  static const pillMoveDuration = Duration(milliseconds: 300);
  static const pillResizeDuration = Duration(milliseconds: 200);
  static const pillTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  late int selectedIndex;
  late final VoidCallback _pageListener;

  bool _fadeSelected = true;
  bool _firstFrame = true;

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
          _fadeSelected = true;
        });
      }
    };

    widget.controller.addListener(_pageListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _firstFrame = false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_pageListener);
    super.dispose();
  }

  void _onItemTap(int index) {
    if (index == selectedIndex) return;

    setState(() {
      selectedIndex = index;
      _fadeSelected = false;
    });

    widget.controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (index == selectedIndex) {
        setState(() => _fadeSelected = true);
      }
    });
  }

  double _estimatePillWidthForAction(
      BuildContext context, PageIndicatorActions action,
      {Color? color}) {
    final text = action.name(context);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: pillTextStyle.copyWith(color: color),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return pillIconWidth +
        pillIconSpacing +
        textPainter.width +
        pillHorizontalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = Colors.black.withAlpha(20);
    final pillColor = theme.colorScheme.surfaceContainer;
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.primary;

    final visibleActions = PageIndicatorActions.all
        .where(
            (action) => action.canShow?.call(widget.dashboardViewModel) ?? true)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = _estimatePillWidthForAction(
        context, visibleActions[selectedIndex],
        color: activeColor);

    final baseWidth = screenWidth * 0.6;
    final maxPillWidth = visibleActions
        .map((a) => _estimatePillWidthForAction(context, a))
        .reduce(math.max);
    final minRequiredWidth =
        maxPillWidth + (visibleActions.length - 1) * (maxPillWidth * 0.7);
    final barWidth =
        math.min(screenWidth * 0.9, math.max(baseWidth, minRequiredWidth));

    const double edgePadding = 5.0;
    final double firstItemLeft = edgePadding;
    final double lastItemLeft = barWidth - pillWidth - edgePadding;
    final double centerOfBar = barWidth / 2;
    final double halfPill = pillWidth / 2;
    final double centerItemLeft = centerOfBar - halfPill;

    final List<double> positions = [
      firstItemLeft,
      centerItemLeft,
      lastItemLeft
    ];

    final double left = positions[selectedIndex];
    final currentAction = visibleActions[selectedIndex];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 10),
        child: AnimatedContainer(
          duration: barResizeDuration,
          curve: Curves.easeOutCubic,
          width: barWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barBorderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                        pillIconHeight: pillIconHeight,
                        pillIconWidth: pillIconWidth,
                        pillIconSpacing: pillIconSpacing,
                        pillBorderRadius: pillBorderRadius,
                        contentColor: activeColor,
                        estimateWidthForAction: pillWidth,
                        pillTextStyle: pillTextStyle,
                        pillMoveDuration: pillMoveDuration,
                        pillResizeDuration: pillResizeDuration,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (int i = 0; i < visibleActions.length; i++)
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => _onItemTap(i),
                                child: SizedBox(
                                  height: barHeight,
                                  child: AnimatedContainer(
                                    duration: _firstFrame
                                        ? Duration.zero
                                        : inactiveIconMoveDuration,
                                    curve: Curves.easeOutCubic,
                                    width: i == selectedIndex
                                        ? pillWidth
                                        : _estimatePillWidthForAction(
                                            context, visibleActions[i]),
                                    alignment: Alignment.center,
                                    child: AnimatedOpacity(
                                      duration: inactiveIconFadeDuration,
                                      curve: Curves.easeOutCubic,
                                      opacity:
                                          (i == selectedIndex && _fadeSelected)
                                              ? 0.0
                                              : 1.0,
                                      child: AnimatedScale(
                                        duration: inactiveIconAppearDuration,
                                        curve: Curves.easeOutCubic,
                                        scale:
                                            (i == selectedIndex) ? 0.95 : 1.0,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              visibleActions[i].image,
                                              width: iconWidth,
                                              height: iconHeight,
                                              colorFilter: ColorFilter.mode(
                                                inactiveColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            SizedBox(width: pillIconSpacing),
                                            Text(
                                              visibleActions[i].name(context),
                                              style: pillTextStyle.copyWith(
                                                  color: inactiveColor),
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                            ),
                                          ],
                                        ),
                                      ),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: estimateWidthForAction,
          end: estimateWidthForAction,
        ),
        duration: pillResizeDuration,
        curve: Curves.easeOutCubic,
        builder: (context, width, child) {
          return AnimatedContainer(
            duration: pillResizeDuration,
            curve: Curves.easeOutCubic,
            width: width,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(pillBorderRadius),
            ),
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      currentAction.image,
                      width: pillIconWidth,
                      height: pillIconHeight,
                      colorFilter: ColorFilter.mode(
                        contentColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: pillIconSpacing),
                    Text(
                      currentAction.name(context),
                      style: pillTextStyle.copyWith(color: contentColor),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
