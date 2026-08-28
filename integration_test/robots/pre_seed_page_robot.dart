import "package:cake_wallet/new-ui/pages/seed/pre_seed_page.dar"';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';

class PreSeedPageRobot {
  PreSeedPageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isPreSeedPage() async {
    await commonTestCases.isSpecificPage<PreSeedPage>();
    await commonTestCases.takeScreenshots('pre_seed_page');
  }

  Future<void> onConfirmButtonPressed() async {
    await commonTestCases.tapItemByKey("pre_seed_page_only_way_checkbox_key");
    await commonTestCases.tapItemByKey("pre_seed_page_write_down_checkbox_key");
    await commonTestCases.tapItemByKey("pre_seed_page_never_share_checkbox_key");
    await commonTestCases.tapItemByKey('pre_seed_page_button_key');
    await commonTestCases.defaultSleepTime();
  }
}
