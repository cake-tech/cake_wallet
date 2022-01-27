
import 'package:flutter/services.dart';

const _utils = const MethodChannel('com.cake_wallet/native_utils');
Future<void> startReview() async {
  try {
    await _utils.invokeMethod<void>('requestAppReview');
  } catch (e) {
    print('error: ${e.toString()}');
  }
}
