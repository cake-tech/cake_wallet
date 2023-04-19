import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class RequestReviewHandler {
  static const _coolDownDurationInDays = 30;

  static void requestReview() async {
    final sharedPrefs = await SharedPreferences.getInstance();

    final lastReviewRequestDate =
        DateTime.tryParse(sharedPrefs.getString(PreferencesKey.lastAppReviewDate) ?? '') ??
            DateTime.now().subtract(Duration(days: _coolDownDurationInDays + 1));

    final durationSinceLastRequest = DateTime.now().difference(lastReviewRequestDate).inDays;

    if (durationSinceLastRequest < _coolDownDurationInDays) {
      return;
    }

    sharedPrefs.setString(PreferencesKey.lastAppReviewDate, DateTime.now().toString());

    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }
}
