import "package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletListPageRobot extends BaseRobot {
  WalletListPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    final shown = await pumpUntil(_isShowing);

    expect(shown, true, reason: "The wallets tab never came to the front");
  }

  Future<void> openEditFor(String walletName) async {
    await tapByKey("wallet_list_edit_${walletName}_button_key");
  }

  bool hasWallet(String walletName) => tester.any(
        find.descendant(
          of: find.byType(WalletListPage),
          matching: find.text(walletName),
        ),
      );

  Future<void> navigateToCreateNewWalletPage() async {
    await tapByKey("wallet_list_page_create_new_wallet_button_key");
  }

  Future<void> navigateToRestoreWalletOptionsPage() async {
    await tapByKey("wallet_list_page_restore_wallet_button_key");
  }

  bool _isShowing() {
    final stackFinder = find.byType(IndexedStack);

    if (!tester.any(stackFinder)) {
      return false;
    }

    final stack = tester.widget<IndexedStack>(stackFinder.first);
    final index = stack.children.indexWhere((child) => child is WalletListPage);

    return index >= 0 && stack.index == index;
  }
}
