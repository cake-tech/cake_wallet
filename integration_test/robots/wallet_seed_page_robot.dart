import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/seed/wallet_seed_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletSeedPageRobot extends BaseRobot {
  WalletSeedPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletSeedPage>();
  }

  Future<void> onVerifySeedButtonPressed() async {
    await tapByKey("wallet_seed_page_verify_seed_button_key");
  }

  Future<void> onSaveSeedButtonPressed() async {
    await tapByKey("wallet_seed_page_save_seeds_button_key");
  }

  void confirmWalletDetailsDisplayCorrectly() {
    final walletSeedPage = tester.widget<WalletSeedPage>(find.byType(WalletSeedPage));

    final walletSeedViewModel = walletSeedPage.walletSeedViewModel;

    final walletName = walletSeedViewModel.name;
    final walletSeeds = walletSeedViewModel.seedSplit;
    hasText(walletName);
    for (final seed in walletSeeds) {
      hasTextAtLeastOnce(seed);
    }
  }

  void confirmWalletSeedReminderDisplays() {
    hasText(S.current.cake_seeds_save_disclaimer);
  }

  Future<void> onSaveSeedsButtonPressed() async {
    await tapByKey("wallet_seed_page_save_seeds_button_key");
  }

  Future<void> onCopySeedsButtonPressed() async {
    await tapByKey("wallet_seed_page_copy_seeds_button_key");
  }
}
