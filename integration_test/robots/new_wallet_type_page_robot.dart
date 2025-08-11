import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/new_wallet_type_page.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';

class NewWalletTypePageRobot {
  NewWalletTypePageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isNewWalletTypePage() async {
    await commonTestCases.isSpecificPage<NewWalletTypePage>();
    await commonTestCases.takeScreenshots('new_wallet_type_page');
  }

  void displaysCorrectTitle(bool isCreate) {
    commonTestCases.hasText(
      isCreate ? S.current.wallet_list_create_new_wallet : S.current.wallet_list_restore_wallet,
    );
  }

  void hasWalletTypeForm() {
    commonTestCases.hasType<WalletTypeForm>();
  }

  void displaysCorrectImage(ThemeType type) {
    final walletTypeImage = Image.asset('assets/images/wallet_type.png').image;
    final walletTypeLightImage = Image.asset('assets/images/wallet_type_light.png').image;

    find.image(
      type == ThemeType.dark ? walletTypeImage : walletTypeLightImage,
    );
  }

  Future<void> findParticularWalletTypeInScrollableList(WalletType type) async {
    await tester.pump(Duration(milliseconds: 1000));

    final scrollableWidget = find.descendant(
      of: find.byKey(Key('new_wallet_type_scrollable_key')),
      matching: find.byType(Scrollable),
    );

    final targetWidget = find.byKey(ValueKey('new_wallet_type_${type.name}_button_key'));

    tester.printToConsole('Attempting to scroll to wallet type ${type.name}');

    await tester.pump(Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      targetWidget,
      300,
      scrollable: scrollableWidget,
      maxScrolls: 20,
    );

    await tester.pumpAndSettle(Duration(milliseconds: 1000));

    expect(tester.any(targetWidget), true,
        reason: 'Wallet type ${type.name} should be visible after scrolling');

    // Additional check to ensure the widget is actually on screen
    final widgetRect = tester.getRect(targetWidget);
    final screenSize = tester.view.physicalSize;
    final screenRect = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);

    expect(
      screenRect.overlaps(widgetRect),
      true,
      reason: 'Wallet type ${type.name} should be within screen bounds',
    );

    tester.printToConsole('Wallet type ${type.name} is now visible and tappable');
  }

  Future<void> selectWalletType(WalletType type) async {
    await commonTestCases.tapItemByKey('new_wallet_type_${type.name}_button_key');
  }

  Future<void> onNextButtonPressed() async {
    await commonTestCases.tapItemByKey('new_wallet_type_next_button_key');
  }
}
