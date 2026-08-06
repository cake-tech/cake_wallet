import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/seed/seed_verification/seed_verification_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class SeedVerificationPageRobot extends BaseRobot {
  SeedVerificationPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<SeedVerificationPage>();
  }

  void hasTitle() {
    hasText(S.current.verify_seed);
  }

  Future<void> verifyWalletSeeds() async {
    final seedVerificationPage =
        tester.widget<SeedVerificationPage>(find.byType(SeedVerificationPage));

    final walletSeedViewModel = seedVerificationPage.walletSeedViewModel;

    while (!walletSeedViewModel.isVerificationComplete &&
        walletSeedViewModel.verificationWordCount != 0) {
      final currentCorrectWord = walletSeedViewModel.currentCorrectWord;
      final currentStep = walletSeedViewModel.currentStepIndex;

      hasTextAtLeastOnce(currentCorrectWord);

      await tapByKey("seed_verification_option_${currentCorrectWord}_button_key");

      // Tapping the right word moves the view model on to the next one. Waiting for that
      // instead of sleeping keeps the loop from reading the word of the previous step,
      // which would tap an option that is no longer on screen.
      final hasMovedOn = await pumpUntil(
        () =>
            walletSeedViewModel.isVerificationComplete ||
            walletSeedViewModel.currentStepIndex != currentStep,
      );

      if (!hasMovedOn) {
        throw TestFailure("Seed verification never moved past step $currentStep");
      }
    }

    await tapByKey("wallet_seed_page_open_wallet_button_key");
  }
}
