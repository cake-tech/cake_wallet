import "package:cake_wallet/entities/seed_type.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/restore/wallet_restore_page.dart";
import "package:cake_wallet/src/widgets/validable_annotated_editable_text.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class RestoreFromSeedOrKeysPageRobot extends BaseRobot {
  RestoreFromSeedOrKeysPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletRestorePage>();
  }

  Future<void> confirmViewComponentsDisplayProperlyPerPageView() async {
    hasText(S.current.wallet_name);
    hasText(S.current.enter_seed_phrase);
    hasText(S.current.restore_title_from_seed);

    hasValueKey("wallet_restore_from_seed_wallet_name_textfield_key");
    hasValueKey("wallet_restore_from_seed_wallet_name_refresh_button_key");
    hasValueKey("wallet_restore_from_seed_wallet_seeds_paste_button_key");
    hasValueKey("wallet_restore_from_seed_wallet_seeds_textfield_key");

    hasText(S.current.private_key, isVisible: false);
    hasText(S.current.restore_title_from_keys, isVisible: false);

    await swipePage();

    hasText(S.current.wallet_name);
    hasText(S.current.private_key);
    hasText(S.current.restore_title_from_keys);

    hasText(S.current.enter_seed_phrase, isVisible: false);
    hasText(S.current.restore_title_from_seed, isVisible: false);

    await swipePage(swipeRight: false);
  }

  void confirmRestoreButtonDisplays() {
    hasValueKey("wallet_restore_seed_or_key_restore_button_key");
  }

  void confirmAdvancedSettingButtonDisplays() {
    hasValueKey("wallet_restore_advanced_settings_button_key");
  }

  Future<void> enterWalletNameText(String walletName, {bool isSeedFormEntry = true}) async {
    await enterTextByKey(
      'wallet_restore_from_${isSeedFormEntry ? 'seed' : 'keys'}_wallet_name_textfield_key',
      walletName,
    );
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

  Future<void> onPasteSeedPhraseButtonPressed() async {
    await tapByKey("wallet_restore_from_seed_wallet_seeds_paste_button_key");
  }

  Future<void> enterPrivateKeyForWalletRestore(String privateKey) async {
    await enterTextByKey("wallet_restore_from_key_private_key_textfield_key", privateKey);
    await settle();
  }

  Future<void> expectRestoreRefused({Duration window = const Duration(seconds: 10)}) async {
    final left = await pumpUntil(
      () => !tester.any(find.byType(WalletRestorePage)),
      timeout: window,
    );

    expect(left, false, reason: "A seed the wallet cannot parse still restored something");
  }

  Future<void> onRestoreWalletButtonPressed() async {
    await tapByKey("wallet_restore_seed_or_key_restore_button_key");
  }
}
