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
    required this.selectedIndex,
    required this.onItemTap,
  });

  final DashboardViewModel dashboardViewModel;
  final int selectedIndex;
  final Function(int index) onItemTap;

  @override
  State<NewMainNavBar> createState() => _NEWNewMainNavBarState();
}

class _NEWNewMainNavBarState extends State<NewMainNavBar> {

  static const barHeight = 64.0;
  static const barBottomPadding = 32.0;

  static const iconWidth = 28.0;
  static const iconHeight = 28.0;
  static const iconHorizontalPadding = 12.0;

  static const pillIconWidth = 24.0;
  static const pillIconHeight = 24.0;
  static const pillIconSpacing = 4.0;
  static const pillHorizontalPadding = 20.0;

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

  bool _firstFrame = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _firstFrame = false);
    });
  }

  void _onItemTap(int index) {
    // if (index == widget.selectedIndex) return;
    //
    // setState(() {
    //   widget.selectedIndex = index;
    // });

    widget.onItemTap(index);

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
    if (index > widget.selectedIndex) additionalSpacing = pillWidth-iconWidth-iconHorizontalPadding/2;
     else additionalSpacing = 0;

    return baseOffset + additionalSpacing;
  }

  double calcBarWidth(double pillWidth) {
    return (iconWidth+iconHorizontalPadding)*(NewMainActions.all.length)+(pillWidth-(iconWidth))+barHorizontalPadding+pillIconSpacing/2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        theme.colorScheme.surfaceContainer.withAlpha(127);
    final pillColor = theme.colorScheme.onSurface.withAlpha(25);
    final activeColor = theme.colorScheme.onSurface;
    final inactiveColor = theme.colorScheme.primary;

    final visibleActions = NewMainActions.all
        .where(
            (action) => action.canShow?.call(widget.dashboardViewModel) ?? true)
        .toList();

    final pillWidth = _estimatePillWidthForAction(
        context, visibleActions[widget.selectedIndex],
        color: activeColor);

    final barWidth = calcBarWidth(pillWidth);

    final currentAction = visibleActions[widget.selectedIndex];

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
                      border: Border.all(color: Color(0x14FFFFFF), width: 1),
                      borderRadius: BorderRadius.circular(barBorderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: barHorizontalPadding),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPill(
                            left: calcLeft(widget.selectedIndex, pillWidth),
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
                              left: calcLeft(i, pillWidth)+((i == widget.selectedIndex) ? iconHorizontalPadding/2 : 0),
                              curve: Curves.easeOutCubic,
                              child: GestureDetector(
                                onTap: () => _onItemTap(i),
                                child: AnimatedContainer(
                                  duration: _firstFrame
                                      ? Duration.zero
                                      : inactiveIconMoveDuration,
                                  curve: Curves.easeOutCubic,
                                  width:
                                      i == widget.selectedIndex ? pillWidth : iconWidth,
                                  height: iconHeight,
                                  alignment: Alignment.center,
                                  child: AnimatedAlign(
                                    duration: inactiveIconFadeDuration,
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedScale(
                                      duration: inactiveIconAppearDuration,
                                      curve: Curves.easeOutCubic,
                                      scale: (i == widget.selectedIndex) ? 0.857 : 1.0,
                                      child: TweenAnimationBuilder<Color?>(
                                          tween: ColorTween(
                                            begin: (i == widget.selectedIndex) ? inactiveColor : activeColor,
                                            end: (i==widget.selectedIndex) ? activeColor : inactiveColor,
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
        top: 8,
        bottom: 8,
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
                // SizedBox(width: pillIconSpacing*10),
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
