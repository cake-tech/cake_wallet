import 'package:flutter/foundation.dart';
import 'dart:io';

class FeatureFlag {
  static const bool isCakePayEnabled = false;
  static const bool isCakePayRedemptionFlowEnabled = false;
  static const bool isExolixEnabled = true;
  static const bool isBackgroundSyncEnabled = true;
  static final bool isInAppTorEnabled = (Platform.isAndroid);
  static const int verificationWordsCount = kDebugMode ? 0 : 2;
  static const bool hasDevOptions = bool.fromEnvironment('hasDevOptions', defaultValue: kDebugMode);
  static const bool hasBitcoinViewOnly = true;
}
