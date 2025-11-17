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

  static const barHeight = 64.0;
  static const barBottomPadding = 32.0;

  static const iconWidth = 28.0;
  static const iconHeight = 28.0;
  static const iconHorizontalPadding = 12.0;

  static const pillIconWidth = 20.0;
  static const pillIconHeight = 20.0;
  static const pillIconSpacing = 4.0;
  static const pillHorizontalPadding = 16.0;

  static const barBorderRadius = 50.0;
  static const pillBorderRadius = 50.0;

  static const barHorizontalPadding = 12.0;

  static const barResizeDuration = Duration(milliseconds: 300);
  static const inactiveIconMoveDuration = Duration(milliseconds: 300);
  static const inactiveIconFadeDuration = Duration(milliseconds: 300);
  static const inactiveIconAppearDuration = Duration(milliseconds: 300);
  static const pillMoveDuration = Duration(milliseconds: 250);
  static const pillResizeDuration = Duration(milliseconds: 250);
  static const iconColorChangeDuration = Duration(milliseconds: 200);

  static const pillTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  int selectedIndex = 0;
  bool _fadeSelected = false;
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
        pillHorizontalPadding;
  }

  double calcLeft(int index, double pillWidth) {
    final double baseOffset = (iconWidth+iconHorizontalPadding) * index;

    double additionalSpacing;
    if (index > selectedIndex) additionalSpacing = pillWidth-iconWidth;
     else additionalSpacing = 0;

    return baseOffset + additionalSpacing;
  }

  double calcBarWidth(double pillWidth) {
    return (iconWidth+iconHorizontalPadding)*NewMainActions.all.length+(pillWidth-iconWidth)+barHorizontalPadding;
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

    final pillWidth = _estimatePillWidthForAction(
        context, visibleActions[selectedIndex],
        color: activeColor);

    final barWidth = calcBarWidth(pillWidth);

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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: barHorizontalPadding),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPill(
                            left: calcLeft(selectedIndex, pillWidth),
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
                          for (int i = 0; i < visibleActions.length; i++)
                            AnimatedPositioned(
                              duration: pillResizeDuration,
                              left: calcLeft(i, pillWidth),
                              curve: Curves.easeOutCubic,
                              child: GestureDetector(
                                onTap: () => _onItemTap(i),
                                child: AnimatedContainer(
                                  duration: _firstFrame
                                      ? Duration.zero
                                      : inactiveIconMoveDuration,
                                  curve: Curves.easeOutCubic,
                                  width:
                                      i == selectedIndex ? pillWidth : iconWidth,
                                  height: iconHeight,
                                  alignment: Alignment.center,
                                  child: AnimatedAlign(
                                    duration: inactiveIconFadeDuration,
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedScale(
                                      duration: inactiveIconAppearDuration,
                                      curve: Curves.easeOutCubic,
                                      scale: (i == selectedIndex) ? 0.8 : 1.0,
                                      child: TweenAnimationBuilder<Color?>(
                                          tween: ColorTween(
                                            begin: (i == selectedIndex) ? inactiveColor : activeColor,
                                            end: (i==selectedIndex) ? activeColor : inactiveColor,
                                          ),
                                        duration: iconColorChangeDuration,
                                        builder: (context, value, child) {
                                          return SvgPicture.asset(
                                            visibleActions[i].image,
                                            width: iconWidth,
                                            height: iconHeight,
                                            colorFilter: ColorFilter.mode(
                                              value ?? inactiveColor,
                                              BlendMode.srcIn,
                                            ),
                                          );
                                        }
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
        child: AnimatedContainer(
          duration: pillResizeDuration,
          curve: Curves.easeOutCubic,
          width: estimateWidthForAction,
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(pillBorderRadius),
          ),
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: pillIconSpacing),
                Padding(padding: EdgeInsets.only(left: pillIconWidth),
                  child: Text(
                    currentAction.name(context),
                    style: pillTextStyle.copyWith(color: contentColor),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}