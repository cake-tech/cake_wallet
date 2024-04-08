import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_keys_form.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_seed_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/sign_view_model.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/seed_type_view_model.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cw_core/nano_account_info_response.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:polyseed/polyseed.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SignPage extends BasePage {
  SignPage(this.signViewModel)
      : walletRestoreFromSeedFormKey = GlobalKey<WalletRestoreFromSeedFormState>(),
        walletRestoreFromKeysFormKey = GlobalKey<WalletRestoreFromKeysFromState>(),
        _pages = [],
        _blockHeightFocusNode = FocusNode(),
        _controller = PageController(initialPage: 0) {
    // walletRestoreViewModel.availableModes.forEach((mode) {
    //   switch (mode) {
    //     case WalletRestoreMode.seed:
    //       _pages.add(WalletRestoreFromSeedForm(
    //           seedTypeViewModel: seedTypeViewModel,
    //           displayBlockHeightSelector:
    //               walletRestoreViewModel.hasBlockchainHeightLanguageSelector,
    //           displayLanguageSelector: walletRestoreViewModel.hasSeedLanguageSelector,
    //           type: walletRestoreViewModel.type,
    //           key: walletRestoreFromSeedFormKey,
    //           blockHeightFocusNode: _blockHeightFocusNode,
    //           onHeightOrDateEntered: (value) {
    //           },
    //           onSeedChange: (String seed) {
    //             final isPolyseed =
    //                 walletRestoreViewModel.type == WalletType.monero && Polyseed.isValidSeed(seed);
    //             _validateOnChange(isPolyseed: isPolyseed);
    //           },
    //           onLanguageChange: (String language) {
    //             final isPolyseed = language.startsWith("POLYSEED_");
    //             _validateOnChange(isPolyseed: isPolyseed);
    //           }));
    //       break;
    //     case WalletRestoreMode.keys:
    //       _pages.add(WalletRestoreFromKeysFrom(
    //           key: walletRestoreFromKeysFormKey,
    //           walletRestoreViewModel: walletRestoreViewModel,
    //           onPrivateKeyChange: (String seed) {
    //             if (walletRestoreViewModel.type == WalletType.nano ||
    //                 walletRestoreViewModel.type == WalletType.banano) {
    //             }
    //           },
    //           displayPrivateKeyField: walletRestoreViewModel.hasRestoreFromPrivateKey,
    //           onHeightOrDateEntered: (value) => walletRestoreViewModel.isButtonEnabled = value));
    //       break;
    //     default:
    //       break;
    //   }
    // });
  }

  @override
  Widget middle(BuildContext context) => Observer(
      builder: (_) => Text(
            "Sign / Verify",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
              color: titleColor(context),
            ),
          ));

  final SignViewModel signViewModel;
  final PageController _controller;
  final List<Widget> _pages;
  final GlobalKey<WalletRestoreFromSeedFormState> walletRestoreFromSeedFormKey;
  final GlobalKey<WalletRestoreFromKeysFromState> walletRestoreFromKeysFormKey;
  final FocusNode _blockHeightFocusNode;
  DerivationType derivationType = DerivationType.unknown;
  String? derivationPath = null;

  @override
  Widget body(BuildContext context) {
    // reaction((_) => walletRestoreViewModel.state, (ExecutionState state) {
    //   if (state is FailureState) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       showPopUp<void>(
    //           context: context,
    //           builder: (_) {
    //             return AlertWithOneAction(
    //                 alertTitle: S.current.new_wallet,
    //                 alertContent: state.error,
    //                 buttonText: S.of(context).ok,
    //                 buttonAction: () => Navigator.of(context).pop());
    //           });
    //     });
    //   }
    // });

    // reaction((_) => walletRestoreViewModel.mode, (WalletRestoreMode mode) {
    //   walletRestoreViewModel.isButtonEnabled = false;

    //   walletRestoreFromSeedFormKey
    //       .currentState!.blockchainHeightKey.currentState!.restoreHeightController.text = '';
    //   walletRestoreFromSeedFormKey
    //       .currentState!.blockchainHeightKey.currentState!.dateController.text = '';
    //   walletRestoreFromSeedFormKey.currentState!.nameTextEditingController.text = '';

    //   walletRestoreFromKeysFormKey
    //       .currentState!.blockchainHeightKey.currentState!.restoreHeightController.text = '';
    //   walletRestoreFromKeysFormKey
    //       .currentState!.blockchainHeightKey.currentState!.dateController.text = '';
    //   walletRestoreFromKeysFormKey.currentState!.nameTextEditingController.text = '';
    // });

    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: _blockHeightFocusNode,
            toolbarButtons: [(_) => KeyboardDoneButton()],
          )
        ],
      ),
      child: Container(
        height: 0,
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: PageView.builder(
                    onPageChanged: (page) {
                      // walletRestoreViewModel.mode =
                      //     page == 0 ? WalletRestoreMode.seed : WalletRestoreMode.keys;
                    },
                    controller: _controller,
                    itemCount: _pages.length,
                    itemBuilder: (_, index) => SingleChildScrollView(child: _pages[index]),
                  ),
                ),
                if (_pages.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ColorTransitionEffect(
                        spacing: 6.0,
                        radius: 6.0,
                        dotWidth: 6.0,
                        dotHeight: 6.0,
                        dotColor: Theme.of(context).hintColor.withOpacity(0.5),
                        activeDotColor: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 24, left: 24, right: 24),
                  child: Column(
                    children: [
                      Observer(
                        builder: (context) {
                          return LoadingPrimaryButton(
                            onPressed: () async {
                              await _confirmForm(context);
                            },
                            text: S.of(context).restore_recover,
                            color: Theme.of(context)
                                .extension<WalletListTheme>()!
                                .createNewWalletButtonBackgroundColor,
                            textColor: Theme.of(context)
                                .extension<WalletListTheme>()!
                                .restoreWalletButtonTextColor,
                            // isLoading: walletRestoreViewModel.state is IsExecutingState,
                            // isDisabled: !walletRestoreViewModel.isButtonEnabled,
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          // Navigator.of(context)
                          //     .pushNamed(Routes.advancedPrivacySettings, arguments: {
                          //   'type': walletRestoreViewModel.type,
                          //   'useTestnet': walletRestoreViewModel.useTestnet,
                          //   'toggleTestnet': walletRestoreViewModel.toggleUseTestnet
                          // });
                        },
                        child: Text(S.of(context).advanced_settings),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateOnChange({bool isPolyseed = false}) {}

  Future<void> _confirmForm(BuildContext context) async {
    // // Dismissing all visible keyboard to provide context for navigation
    // FocusManager.instance.primaryFocus?.unfocus();

    // late BuildContext? formContext;
    // late GlobalKey<FormState>? formKey;
    // late String name;
    // if (walletRestoreViewModel.mode == WalletRestoreMode.seed) {
    //   formContext = walletRestoreFromSeedFormKey.currentContext;
    //   formKey = walletRestoreFromSeedFormKey.currentState!.formKey;
    //   name = walletRestoreFromSeedFormKey.currentState!.nameTextEditingController.value.text;
    // } else if (walletRestoreViewModel.mode == WalletRestoreMode.keys) {
    //   formContext = walletRestoreFromKeysFormKey.currentContext;
    //   formKey = walletRestoreFromKeysFormKey.currentState!.formKey;
    //   name = walletRestoreFromKeysFormKey.currentState!.nameTextEditingController.value.text;
    // }

    // if (!formKey!.currentState!.validate()) {
    //   return;
    // }
  }

  Future<void> showNameExistsAlert(BuildContext context) {
    return showPopUp<void>(
        context: context,
        builder: (_) {
          return AlertWithOneAction(
              alertTitle: '',
              alertContent: S.of(context).wallet_name_exists,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }
}
