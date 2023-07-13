import 'package:flutter/material.dart';

class ResponsiveLayoutUtil {
  static const double _kMobileThreshold = 550;
  static const double kDesktopMaxWidthConstraint = 400;
  static const double kDesktopMaxDashBoardWidthConstraint = 900;
  static const double kPopupWidth = 400;
  static const double kPopupSpaceHeight = 100;

  const ResponsiveLayoutUtil._();

  static final instance = ResponsiveLayoutUtil._();

  bool get isMobile =>
      MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.shortestSide <=
      _kMobileThreshold;

  bool shouldRenderMobileUI() {
    final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    final orientation = mediaQuery.orientation;
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    if (isMobile ||
        (orientation == Orientation.portrait && width < height) ||
        (orientation == Orientation.landscape && width < height)) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns dynamic size.
  ///
  /// If screen size is mobile, it returns 66% ([scale]) of the [originalValue].
  double getDynamicSize(
    double originalValue, {
    double? mobileSize,
    double? scale,
  }) {
    scale ??= 2 / 3;
    mobileSize ??= originalValue * scale;
    final value = isMobile ? mobileSize : originalValue;

    return value.roundToDouble();
  }
}
