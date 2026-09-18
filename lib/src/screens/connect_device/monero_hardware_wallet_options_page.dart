import "dart:async";

import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/blockchain_height_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/src/widgets/scrollable_with_bottom_section.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/wallet_hardware_restore_view_model.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";

class MoneroHardwareWalletOptionsPage extends BasePage {
  MoneroHardwareWalletOptionsPage(this._walletHardwareRestoreVM);

  final WalletHardwareRestoreViewModel _walletHardwareRestoreVM;

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  Widget body(BuildContext context) => _MoneroHardwareWalletOptionsForm(_walletHardwareRestoreVM);
}

class _MoneroHardwareWalletOptionsForm extends StatefulWidget {
  const _MoneroHardwareWalletOptionsForm(this._walletHardwareRestoreVM);

  final WalletHardwareRestoreViewModel _walletHardwareRestoreVM;

  @override
  _MoneroHardwareWalletOptionsFormState createState() =>
      _MoneroHardwareWalletOptionsFormState(_walletHardwareRestoreVM);
}

class _MoneroHardwareWalletOptionsFormState extends State<_MoneroHardwareWalletOptionsForm> {
  _MoneroHardwareWalletOptionsFormState(this._walletHardwareRestoreVM)
      : _formKey = GlobalKey<FormState>(),
        _blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        _blockHeightFocusNode = FocusNode(),
        _walletNameController = TextEditingController(),
        _passphraseController = TextEditingController();

  final GlobalKey<FormState> _formKey;
  final GlobalKey<BlockchainHeightState> _blockchainHeightKey;
  final FocusNode _blockHeightFocusNode;
  final WalletHardwareRestoreViewModel _walletHardwareRestoreVM;
  final TextEditingController _walletNameController;
  final TextEditingController _passphraseController;

  @override
  void initState() {
    super.initState();
    _setEffects(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: ScrollableWithBottomSection(
          contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Form(
                      key: _formKey,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          BaseTextFormField(
                            onChanged: (value) => _walletHardwareRestoreVM.name = value,
                            controller: _walletNameController,
                            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                            placeholderTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            hintText: S.of(context).wallet_name,
                            suffixIcon: Semantics(
                              label: S.of(context).generate_name,
                              child: IconButton(
                                onPressed: _onGenerateName,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                  width: 34,
                                  height: 34,
                                  child: Image.asset(
                                    "assets/images/refresh_icon.png",
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            validator: WalletNameValidator(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: BlockchainHeightWidget(
                      focusNode: _blockHeightFocusNode,
                      key: _blockchainHeightKey,
                      hasDatePicker: true,
                      walletType: WalletType.monero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomSectionPadding: const EdgeInsets.all(24),
          bottomSection: Observer(
            builder: (_) => Column(
              children: [
                LoadingPrimaryButton(
                  onPressed: _confirmForm,
                  text: S.of(context).seed_language_next,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isDisabled: _walletHardwareRestoreVM.name.isEmpty,
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _onGenerateName() async {
    final rName = await generateName();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _walletNameController.text = rName;
      _walletHardwareRestoreVM.name = rName;
      _walletNameController.selection =
          TextSelection.fromPosition(TextPosition(offset: _walletNameController.text.length));
    });
  }

  Future<void> _confirmForm() async {
    unawaited(
      showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).proceed_on_device,
          alertContent: _walletHardwareRestoreVM.hardwareWalletVM.hardwareWalletType ==
                  HardwareWalletType.trezor
              ? S.of(context).trezor_step_export_watch_only
              : S.of(context).proceed_on_device_description,
          buttonText: S.of(context).cancel,
          alertBarrierDismissible: false,
          buttonAction: () => Navigator.of(context).pop(),
        ),
      ),
    );

    // 0 means "unknown"; a negative sentinel would cross the FFI boundary as a
    // huge unsigned restore height.
    final options = <String, dynamic>{"height": _blockchainHeightKey.currentState?.height ?? 0};

    if (_walletHardwareRestoreVM.passphraseAvailable && _passphraseController.text.isNotEmpty) {
      options["passphrase"] = _passphraseController.text;
    }
    await _walletHardwareRestoreVM.create(options: options);
  }

  bool _effectsInstalled = false;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => _walletHardwareRestoreVM.error, (error) {
      if (error != null) {
        // See SelectHardwareWalletAccountPage: show the reason first, then
        // leave the page on a lost connection.
        final isConnectionError = isHardwareWalletConnectionError(error);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showPopUp<void>(
            context: context,
            builder: (dialogContext) => AlertWithOneAction(
              alertTitle: S.of(dialogContext).error,
              alertContent: error,
              buttonText: S.of(dialogContext).ok,
              buttonAction: () {
                _walletHardwareRestoreVM.error = null;
                Navigator.of(dialogContext).pop();
                if (isConnectionError && context.mounted) Navigator.of(context).pop();
              },
            ),
          );
        });
      }
    });

    _effectsInstalled = true;
  }
}
