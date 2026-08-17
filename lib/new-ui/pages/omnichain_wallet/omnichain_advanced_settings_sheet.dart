import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/new_wallet/advanced_privacy_settings_page.dart";
import "package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart";
import "package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart";
import "package:cake_wallet/view_model/seed_settings_view_model.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class OmniChainAdvancedSettingsSheet extends StatelessWidget {
  const OmniChainAdvancedSettingsSheet({
    required this.isFromRestore,
    required this.isChildWallet,
    required this.useTestnet,
    required this.toggleUseTestnet,
    required this.zcashNetwork,
    required this.setZcashNetwork,
    required this.advancedPrivacySettingsViewModel,
    required this.nodeViewModel,
    required this.seedSettingsViewModel,
    this.onPassphraseSaved,
    super.key,
  });

  final bool isFromRestore;
  final bool isChildWallet;
  final bool useTestnet;
  final Function(bool? val) toggleUseTestnet;
  final int zcashNetwork;
  final void Function(int network) setZcashNetwork;
  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;
  final SeedSettingsViewModel seedSettingsViewModel;
  final void Function(String? passphrase)? onPassphraseSaved;

  static Future<void> show(
    BuildContext context, {
    required List<WalletType> types,
    required bool useTestnet,
    required Function(bool? val) toggleUseTestnet,
    required int zcashNetwork,
    required void Function(int network) setZcashNetwork,
    bool isFromRestore = false,
    bool isChildWallet = false,
    void Function(String? passphrase)? onPassphraseSaved,
  }) {
    final viewModelParam = {
      "type": types.length == 1 ? types.first : WalletType.none,
      "isPow": false,
    };

    return showCupertinoModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(85),
      builder: (_) => Material(
        child: OmniChainAdvancedSettingsSheet(
          isFromRestore: isFromRestore,
          isChildWallet: isChildWallet,
          useTestnet: useTestnet,
          toggleUseTestnet: toggleUseTestnet,
          zcashNetwork: zcashNetwork,
          setZcashNetwork: setZcashNetwork,
          advancedPrivacySettingsViewModel:
              getIt.get<AdvancedPrivacySettingsViewModel>(param1: types),
          nodeViewModel: getIt.get<NodeCreateOrEditViewModel>(param1: viewModelParam),
          seedSettingsViewModel: getIt.get<SeedSettingsViewModel>(),
          onPassphraseSaved: onPassphraseSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalTopBar(
              title: S.of(context).privacy_settings,
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              onLeadingPressed: Navigator.of(context).pop,
              leadingSemanticLabel: S.of(context).close,
            ),
            Expanded(
              child: AdvancedPrivacySettingsBody(
                isFromRestore,
                isChildWallet,
                useTestnet,
                toggleUseTestnet,
                zcashNetwork,
                setZcashNetwork,
                advancedPrivacySettingsViewModel,
                nodeViewModel,
                seedSettingsViewModel,
                onPassphraseSaved: onPassphraseSaved,
              ),
            ),
          ],
        ),
      );
}
