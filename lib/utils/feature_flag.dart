import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter/foundation.dart';

class FeatureFlag {
  static const bool isCakePayEnabled = false;
  static const bool isCakePayRedemptionFlowEnabled = false;
  static const bool isExolixEnabled = true;
  static const bool isBackgroundSyncEnabled = true;
  static final bool isInAppTorEnabled = CakeTor.instance is! CakeTorDisabled;
  static const int verificationWordsCount = kDebugMode ? 0 : 2;
  static const bool hasDevOptions = bool.fromEnvironment('hasDevOptions', defaultValue: kDebugMode);
  static const bool hasBitcoinViewOnly = true;
}
