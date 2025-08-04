import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletEditPage extends BasePage {
  WalletEditPage({
    required this.pageArguments,
  })  : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(),
        walletEditViewModel = pageArguments.walletEditViewModel!,
        super() {
    _labelController.text =
        pageArguments.isWalletGroup ? pageArguments.groupName : pageArguments.editingWallet.name;
    _labelController.addListener(() => walletEditViewModel.newName = _labelController.text);
  }

  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;

  final WalletEditPageArguments pageArguments;
  final WalletEditViewModel walletEditViewModel;

  @override
  String get title => pageArguments.isWalletGroup
      ? S.current.wallet_list_edit_group_name
      : S.current.wallet_list_edit_wallet;

  Flushbar<void>? _progressBar;

  @override
  Widget body(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: BaseTextFormField(
                  controller: _labelController,
                  hintText: S.of(context).wallet_list_wallet_name,
                  validator: WalletNameValidator(),
                ),
              ),
            ),
            Observer(
              builder: (_) {
                final isLoading = walletEditViewModel.state is WalletEditRenamePending ||
                    walletEditViewModel.state is WalletEditDeletePending;

                return Row(
                  children: <Widget>[
                    if (!pageArguments.isWalletGroup)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.only(right: 8.0),
                          child: LoadingPrimaryButton(
                            isDisabled: isLoading,
                            onPressed: () => _removeWallet(context),
                            text: S.of(context).delete,
                            color: Theme.of(context).colorScheme.errorContainer,
                            textColor: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.only(left: 8.0),
                        child: LoadingPrimaryButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (!pageArguments.isWalletGroup &&
                                  pageArguments.walletNewVM!
                                      .nameExists(walletEditViewModel.newName)) {
                                showPopUp<void>(
                                  context: context,
                                  builder: (_) {
                                    return AlertWithOneAction(
                                      alertTitle: '',
                                      alertContent: S.of(context).wallet_name_exists,
                                      buttonText: S.of(context).ok,
                                      buttonAction: () => Navigator.of(context).pop(),
                                    );
                                  },
                                );
                              } else {
                                try {
                                  bool confirmed = false;

                                  if (SettingsStoreBase.walletPasswordDirectInput) {
                                    await Navigator.of(context).pushNamed(
                                        Routes.walletUnlockLoadable,
                                        arguments: WalletUnlockArguments(
                                            authPasswordHandler: (String password) async {
                                              await walletEditViewModel.changeName(
                                                pageArguments.editingWallet,
                                                password: password,
                                                isWalletGroup: pageArguments.isWalletGroup,
                                                walletGroupKey: pageArguments.walletGroupKey,
                                              );
                                            },
                                            callback: (bool isAuthenticatedSuccessfully,
                                                AuthPageState auth) async {
                                              if (isAuthenticatedSuccessfully) {
                                                auth.close();
                                                confirmed = true;
                                              }
                                            },
                                            walletName: pageArguments.editingWallet.name,
                                            walletType: pageArguments.editingWallet.type));
                                  } else {
                                    await walletEditViewModel.changeName(
                                      pageArguments.editingWallet,
                                      isWalletGroup: pageArguments.isWalletGroup,
                                      walletGroupKey: pageArguments.walletGroupKey,
                                    );
                                    confirmed = true;
                                  }

                                  if (confirmed) {
                                    Navigator.of(context).pop();
                                    walletEditViewModel.resetState();
                                  }
                                } catch (e) {}
                              }
                            }
                          },
                          text: S.of(context).save,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          isDisabled: walletEditViewModel.newName.isEmpty || isLoading,
                        ),
                      ),
                    )
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _removeWallet(BuildContext context) async {
    pageArguments.authService!.authenticateAction(
      context,
      onAuthSuccess: (isAuthenticatedSuccessfully) async {
        if (!isAuthenticatedSuccessfully) {
          return;
        }

        _onSuccessfulAuth(context);
      },
      conditionToDetermineIfToUse2FA: false,
    );
  }

  void _onSuccessfulAuth(BuildContext context) async {
    bool confirmed = false;

    await showPopUp<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertWithTwoActions(
          alertTitle: S.of(context).delete_wallet,
          alertContent:
              S.of(context).delete_wallet_confirm_message(pageArguments.editingWallet.name),
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).delete,
          actionLeftButton: () => Navigator.of(dialogContext).pop(),
          actionRightButton: () {
            confirmed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (confirmed) {
      Navigator.of(context).pop();

      try {
        changeProcessText(
            context, S.of(context).wallet_list_removing_wallet(pageArguments.editingWallet.name));
        await walletEditViewModel.remove(pageArguments.editingWallet);
        hideProgressText();
      } catch (e) {
        changeProcessText(
          context,
          S
              .of(context)
              .wallet_list_failed_to_remove(pageArguments.editingWallet.name, e.toString()),
        );
      }
    }
  }

  void changeProcessText(BuildContext context, String text) {
    _progressBar = createBar<void>(text, context, duration: null)..show(context);
  }

  Future<void> hideProgressText() async {
    await Future.delayed(Duration(milliseconds: 50), () {
      _progressBar?.dismiss();
      _progressBar = null;
    });
  }
}
