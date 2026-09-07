import "package:flutter_test/flutter_test.dart";

class FundsOutcome {
  static const marker = "FUNDS_RESULT";

  static void ok(WidgetTester tester, String chain, String detail) =>
      _write(tester, chain, "ok", detail);

  static void empty(WidgetTester tester, String chain, String detail) =>
      _write(tester, chain, "empty", detail);

  static void waiting(WidgetTester tester, String chain, String detail) =>
      _write(tester, chain, "waiting", detail);

  static void failed(WidgetTester tester, String chain, String detail) =>
      _write(tester, chain, statusFor(detail), detail);

  static String statusFor(String detail) {
    if (_isWalletBalanceLow(detail)) {
      return "empty";
    }

    return _isChainTooSlowToSync(detail) ? "waiting" : "failed";
  }

  static bool needsFurtherReview(String detail) => statusFor(detail) == "failed";

  static bool _isChainTooSlowToSync(String detail) {
    final wording = detail.toLowerCase();

    return wording.contains("never became ready to send") ||
        wording.contains("new_dashboard_page_key") ||
        wording.contains("never came to the front");
  }

  // Low wallet balance is not a failure, we just need to add fundsss
  static bool _isWalletBalanceLow(String detail) {
    final wording = detail.toLowerCase();

    return wording.contains("not enough") ||
        wording.contains("wrong balance") ||
        wording.contains("insufficient") ||
        wording.contains("no spendable");
  }

  static void _write(WidgetTester tester, String chain, String status, String detail) {
    final clean = detail.replaceAll("\n", " ").replaceAll("|", "/").trim();

    tester.printToConsole("$marker|$chain|$status|$clean");
  }
}
