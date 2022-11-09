
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _utils = const MethodChannel('com.cake_wallet/native_utils');
const _delayDuration = 30;
const _transactionsInterval = 20;

Future<void> reviewApp()async{
      final sharedPref = getIt
        .get<SharedPreferences>();
       int transactionsCommitted = sharedPref.getInt(PreferencesKey.transactionsCommitted) ?? 0;
    if (transactionsCommitted > 0 && (transactionsCommitted % _transactionsInterval == 0)) {
        //Delay Review Request by 30 seconds
        Future.delayed(const Duration(seconds: _delayDuration), () async {
            await startReview();
        });
      return;
    }

   await sharedPref.setInt(PreferencesKey.transactionsCommitted, transactionsCommitted++);
  }
  
Future<void> startReview() async {
  try {
    await _utils.invokeMethod<void>('requestAppReview');
  } catch (e) {
    print('error: ${e.toString()}');
  }
}
