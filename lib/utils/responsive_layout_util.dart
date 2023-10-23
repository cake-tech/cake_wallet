import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'responsive_layout_util.g.dart';

class _ResponsiveLayoutUtil = ResponsiveLayoutUtilBase with _$_ResponsiveLayoutUtil;

abstract class ResponsiveLayoutUtilBase with Store, WidgetsBindingObserver {
  static const double _kMobileThreshold = 550;
  static const double kDesktopMaxWidthConstraint = 400;
  static const double kDesktopMaxDashBoardWidthConstraint = 900;
  static const double kPopupWidth = 400;
  static const double kPopupSpaceHeight = 100;

  ResponsiveLayoutUtilBase() {
    WidgetsBinding.instance.addObserver(this);
    final initialMediaQuery = MediaQueryData.fromView(WidgetsBinding.instance!.window);
    updateDeviceInfo(initialMediaQuery);
  }

  @override
  void didChangeMetrics() {
    final mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance!.window);
    updateDeviceInfo(mediaQuery);
  }

  @observable
  double screenWidth = 0.0;

  @observable
  double screenHeight = 0.0;

  @observable
  Orientation orientation = Orientation.portrait;

  @action
  void updateDeviceInfo(MediaQueryData mediaQuery) {
    orientation = mediaQuery.orientation;
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }

  @computed
  bool get shouldRenderMobileUI {
    return (screenWidth <= _kMobileThreshold) ||
        (orientation == Orientation.portrait && screenWidth < screenHeight) ||
        (orientation == Orientation.landscape && screenWidth < screenHeight);
  }
}

_ResponsiveLayoutUtil _singletonResponsiveLayoutUtil = _ResponsiveLayoutUtil();

_ResponsiveLayoutUtil get responsiveLayoutUtil => _singletonResponsiveLayoutUtil;
