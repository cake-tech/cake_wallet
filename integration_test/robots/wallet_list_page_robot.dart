import "package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletListPageRobot extends BaseRobot {
  WalletListPageRobot(super.tester);

  // Every dashboard tab stays mounted in an IndexedStack, so the list being in the tree says
  // nothing about it being on screen. Which index the stack is showing does.
  @override
  Future<void> isDisplayed() async {
    final shown = await pumpUntil(_isShowing);

    expect(shown, true, reason: "The wallets tab never came to the front");
  }

  // The button is only built for a wallet that is not the open one, since the wallet you are
  // in cannot be renamed or deleted from under you.
  Future<void> openEditFor(String walletName) async {
    await tapByKey("wallet_list_edit_${walletName}_button_key");
  }

  // Scoped to the list because the home page behind it holds the open wallet's name too.
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
