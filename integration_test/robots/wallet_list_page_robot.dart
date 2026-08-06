import "package:cake_wallet/generated/i18n.dart";

import "../core/base_robot.dart";

class WalletListPageRobot extends BaseRobot {
  WalletListPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async => displaysCorrectTitle();

  void displaysCorrectTitle() {
    hasText(S.current.wallets);
  }

  Future<void> navigateToCreateNewWalletPage() async {
    await tapByKey("wallet_list_page_create_new_wallet_button_key");
  }

  Future<void> navigateToRestoreWalletOptionsPage() async {
    await tapByKey("wallet_list_page_restore_wallet_button_key");
  }
}
