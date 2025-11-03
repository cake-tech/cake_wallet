import 'dart:math' as math;
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
  State<NewMainNavBar> createState() => _NEWNewMainNavBarState();
}

class _NEWNewMainNavBarState extends State<NewMainNavBar> {
  static const kBarFlex = 0.85;

  static const barHeight = 64.0;
  static const barBottomPadding = 32.0;

  static const iconWidth = 28.0;
  static const iconHeight = 28.0;

  static const pillIconWidth = 20.0;
  static const pillIconHeight = 20.0;
  static const pillIconSpacing = 8.0;
  static const pillHorizontalPadding = 14.0;

  static const barBorderRadius = 50.0;
  static const pillBorderRadius = 50.0;

  static const barResizeDuration = Duration(milliseconds: 400);
  static const inactiveIconMoveDuration = Duration(milliseconds: 150);
  static const inactiveIconFadeDuration = Duration(milliseconds: 100);
  static const inactiveIconAppearDuration = Duration(milliseconds: 250);
  static const pillMoveDuration = Duration(milliseconds: 300);
  static const pillResizeDuration = Duration(milliseconds: 200);

  static const pillTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  late int selectedIndex;
  bool _fadeSelected = true;
  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _firstFrame = false);
    });
  }

  void _onItemTap(int index) {
    if (index == selectedIndex) return;

    setState(() {
      selectedIndex = index;
      _fadeSelected = false;
    });

    // delay fade (tweak duration)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (index == selectedIndex) {
        setState(() => _fadeSelected = true);
      }
    });

    NewMainActions.all[index].onTap.call();
  }

  // Estimate pill width based on text length
  double _estimatePillWidthForAction(
      BuildContext context, NewMainActions action,
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
    final backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withAlpha(85);
    final pillColor = theme.colorScheme.onSurfaceVariant.withAlpha(85);
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.primary;

    final visibleActions = NewMainActions.all
        .where(
            (action) => action.canShow?.call(widget.dashboardViewModel) ?? true)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = _estimatePillWidthForAction(
        context, visibleActions[selectedIndex],
        color: activeColor);

    final baseWidth = screenWidth * 0.65;

    final double baselinePillWidth =
        pillIconWidth + pillIconSpacing + (pillHorizontalPadding * 2) + 8;

    // Dynamic bar width
    final barWidth = math.max(
      baseWidth,
      baseWidth + (pillWidth - baselinePillWidth) * kBarFlex,
    );

    final int itemCount = visibleActions.length;
    const double edgePadding = 10.0;
    final double firstItemLeft = edgePadding;
    final double lastItemLeft = barWidth - pillWidth - edgePadding;

    // Center alignment for middle (3rd) icon
    final double centerOfBar = barWidth / 2;
    final double halfPill = pillWidth / 2;
    final double centerItemLeft = centerOfBar - halfPill;

    // Base even spacing between first → center → last
    final double secondItemLeft =
        firstItemLeft + (centerItemLeft - firstItemLeft) / 2;
    final double fourthItemLeft =
        centerItemLeft + (lastItemLeft - centerItemLeft) / 2;

    // Spacing correction function
    double spacingCorrection(int index) {
      const double maxCorrection = 6.0;
      final double factor =
          (index - (itemCount - 1) / 2).abs() / ((itemCount - 1) / 2);
      return maxCorrection * factor;
    }

    // Apply correction: shift outer icons inward slightly
    final List<double> positions = [
      firstItemLeft + spacingCorrection(0),
      secondItemLeft + spacingCorrection(1) / 2,
      centerItemLeft,
      fourthItemLeft - spacingCorrection(3) / 2,
      lastItemLeft - spacingCorrection(4),
    ];

    final double left = positions[selectedIndex];
    final currentAction = visibleActions[selectedIndex];

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: barBottomPadding),
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (int i = 0; i < visibleActions.length; i++)
                                GestureDetector(
                                  onTap: () => _onItemTap(i),
                                  child: AnimatedContainer(
                                    duration: _firstFrame
                                        ? Duration.zero
                                        : inactiveIconMoveDuration,
                                    curve: Curves.easeOutCubic,
                                    width: i == selectedIndex
                                        ? pillWidth
                                        : iconWidth,
                                    height: iconHeight,
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
                                        child: SvgPicture.asset(
                                          visibleActions[i].image,
                                          width: iconWidth,
                                          height: iconHeight,
                                          colorFilter: ColorFilter.mode(
                                            inactiveColor,
                                            BlendMode.srcIn,
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
  final NewMainActions currentAction;
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
      top: 12,
      bottom: 12,
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
            width: width + 4,
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
