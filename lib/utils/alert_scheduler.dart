import 'package:cake_wallet/entities/alert_frequency.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertScheduler {
  AlertScheduler({required this.sharedPreferences});

  SharedPreferences sharedPreferences;


  Future<Duration> accessTimeDifference(String lastAccessedPk) async {
    final accessTime = DateTime.fromMillisecondsSinceEpoch(
        sharedPreferences.getInt(lastAccessedPk) ?? DateTime.now().millisecondsSinceEpoch);

    return DateTime.now().difference(accessTime);
  }

  Future<void> updateAccessTime(String lastAccessedPk) async {
    await sharedPreferences.setInt(lastAccessedPk, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> shouldShowAlert({
    required AlertFrequency frequency,
    required String lastAccessedPk,
    required String enabledPk,
  }) async {
    final bool enabled = sharedPreferences.getBool(enabledPk) ?? false;

    if (!enabled) {
      return false;
    }

    final duration = await accessTimeDifference(lastAccessedPk);

    bool shouldShow = false;

    if (frequency == AlertFrequency.daily) {
      shouldShow = duration.inDays >= 1;
    } else if (frequency == AlertFrequency.weekly) {
      shouldShow = duration.inDays >= 7;
    } else if (frequency == AlertFrequency.monthly) {
      shouldShow = duration.inDays >= 30;
    }

    // we're going to show the alert, so update the access time to now:
    if (shouldShow) {
      await sharedPreferences.setInt(lastAccessedPk, DateTime.now().millisecondsSinceEpoch);
    }

    return shouldShow;
  }

  static Future<bool> scheduleAlert() async {
    return true;
  }
}
