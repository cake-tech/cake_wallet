import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/src/screens/restore/wallet_restore_page.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/src/widgets/validable_annotated_editable_text.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class RestoreFromSeedOrKeysPageRobot extends BaseRobot {
  RestoreFromSeedOrKeysPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletRestorePage>();
  }

  Future<void> selectWalletNameFromAvailableOptions({bool isSeedFormEntry = true}) async {
    await tapByKey(
      'wallet_restore_from_${isSeedFormEntry ? 'seed' : 'keys'}_wallet_name_refresh_button_key',
    );
  }

  Future<void> enterSeedPhraseForWalletRestore(String text) async {
    final ValidatableAnnotatedEditableTextState seedTextState =
        tester.state(find.byType(ValidatableAnnotatedEditableText));

    seedTextState.widget.controller.text = text;
    await settle();
  }

  Future<void> enterPasswordForWalletRestore(String text) async {
    await enterTextByKey("password", text);
    await settle();
  }

  Future<void> enterPasswordRepeatForWalletRestore(String text) async {
    await enterTextByKey("repeat_wallet_password", text);
    await settle();
  }

  Future<void> enterBlockHeightForWalletRestore(String blockHeight) async {
    await enterTextByKey("wallet_restore_from_seed_blockheight_textfield_key", blockHeight);
    await settle();
  }

  Future<void> chooseSeedTypeForMoneroOrWowneroWallets(MoneroSeedType selectedType) async {
    await tapByKey("wallet_restore_from_seed_seedtype_picker_button_key");

    await tapByKey("picker_items_index_${selectedType.title}_button_key");
  }

  Future<void> expectRestoreRefused({Duration window = const Duration(seconds: 10)}) async {
    final button = tester.widget<LoadingPrimaryButton>(
      find.byKey(const ValueKey("wallet_restore_seed_or_key_restore_button_key")),
    );

    expect(
      button.isDisabled,
      true,
      reason: "The restore button accepted a seed the wallet cannot parse",
    );

    final left = await pumpUntil(
      () => !tester.any(find.byType(WalletRestorePage)),
      timeout: window,
    );

    expect(left, false, reason: "A seed the wallet cannot parse still restored something");
  }

  Future<void> onRestoreWalletButtonPressed() async {
    await tapByKey("wallet_restore_seed_or_key_restore_button_key");
  }

  Future<void> enablePassphrase() async {
    await tapByKey("wallet_restore_has_passphrase_checkbox_key");
    await settle();

    final page = tester.widget<WalletRestorePage>(find.byType(WalletRestorePage));

    expect(
      page.walletRestoreViewModel.hasPassphrase,
      true,
      reason: "The passphrase box did not tick, the wallet would restore without it",
    );
  }

  Future<void> enterPassphrase(String passphrase) async {
    await enterTextByKey(
      "add_passphrase_bottom_sheet_widget_passphrase_textfield_key",
      passphrase,
    );
    await enterTextByKey(
      "add_passphrase_bottom_sheet_widget_confirm_passphrase_textfield_key",
      passphrase,
    );

    await tapByKey("add_passphrase_bottom_sheet_widget_restore_button_key");
  }
}
