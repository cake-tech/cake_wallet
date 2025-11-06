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

    widget.controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 20), () {
      if (!mounted) return;
      setState(() {
        selectedIndex = index;
        _fadeSelected = false;
      });
    });

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

    final double centerCorrection = -barWidth * 0.02;

    final List<double> positions = [
      firstItemLeft,
      centerItemLeft + centerCorrection,
      lastItemLeft,
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
                              Semantics(
                                button: true,
                                label: visibleActions[i].name(context),
                                value: i == selectedIndex ? 'Selected' : null,
                                hint:
                                    'Double tap to open ${visibleActions[i].name(context)} page',
                                enabled: (visibleActions[i]
                                        .isEnabled
                                        ?.call(widget.dashboardViewModel) ??
                                    true),
                                onTap: () => _onItemTap(i),
                                child: GestureDetector(
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
                                        opacity: (i == selectedIndex &&
                                                _fadeSelected)
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
                                                  color: inactiveColor,
                                                ),
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

class AnimatedPill extends StatefulWidget {
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
  State<AnimatedPill> createState() => _AnimatedPillState();
}

class _AnimatedPillState extends State<AnimatedPill> {
  late PageIndicatorActions _visibleAction;
  bool _isFading = false;

  @override
  void initState() {
    super.initState();
    _visibleAction = widget.currentAction;
  }

  @override
  void didUpdateWidget(covariant AnimatedPill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentAction != oldWidget.currentAction) {
      setState(() => _isFading = true);

      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        setState(() => _visibleAction = widget.currentAction);
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _isFading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: widget.pillMoveDuration,
      curve: Curves.easeOutCubic,
      left: widget.left,
      top: 4,
      bottom: 4,
      child: AnimatedContainer(
        duration: widget.pillResizeDuration,
        curve: Curves.easeOutCubic,
        width: widget.estimateWidthForAction,
        decoration: BoxDecoration(
          color: widget.pillColor,
          borderRadius: BorderRadius.circular(widget.pillBorderRadius),
        ),
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFading ? 0.9 : 1.0,
          curve: Curves.easeInOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    _visibleAction.image,
                    width: widget.pillIconWidth,
                    height: widget.pillIconHeight,
                    colorFilter: ColorFilter.mode(
                      widget.contentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: widget.pillIconSpacing),
                  Text(
                    _visibleAction.name(context),
                    style: widget.pillTextStyle.copyWith(
                      color: widget.contentColor,
                    ),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
