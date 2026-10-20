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
    final viewModel = tester.widget<WalletListPage>(find.byType(WalletListPage).first).walletListViewModel;
    final index = viewModel.singleWalletsList.indexWhere((wallet) => wallet.name == walletName);
    if (index != -1) {
      return tapByKey("wallet_list_single_wallet_${index}_edit_button_key");
    }

    final group = viewModel.multiWalletGroups.indexWhere((g) => g.wallets.any((w) => w.name == walletName));
    final wallet = viewModel.multiWalletGroups[group].wallets.indexWhere((w) => w.name == walletName);
    final key = "wallet_list_group_${group}_wallet_${wallet}_edit_button_key";
    if (!tester.any(find.byKey(ValueKey(key)))) {
      await tapByKey("wallet_list_group_${group}_key");
    }
    await tapByKey(key);
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
