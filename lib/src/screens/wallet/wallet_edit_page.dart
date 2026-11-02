import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/wallet_edit_page_arguments.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_edit_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class WalletEditPage extends BasePage {
  WalletEditPage({required this.pageArguments})
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(text: pageArguments.groupName),
        walletEditViewModel = pageArguments.walletEditViewModel! {
    walletEditViewModel.newName = pageArguments.groupName;
    _labelController.addListener(() => walletEditViewModel.newName = _labelController.text);
  }

  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;
  final WalletEditPageArguments pageArguments;
  final WalletEditViewModel walletEditViewModel;

  Flushbar<void>? _progressBar;

  bool get _isMultiWalletGroup =>
      pageArguments.isWalletGroup && !pageArguments.isSingleWalletGroup;

  bool get _canRename => pageArguments.isWalletGroup;

  bool get _canDelete => !_isMultiWalletGroup && !pageArguments.editingWallet.isCurrent;

  @override
  String get title =>
      _isMultiWalletGroup ? S.current.wallet_list_edit_group_name : S.current.wallet_list_edit_wallet;

  @override
  Widget body(BuildContext context) => Form(
    key: _formKey,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _canRename ? _buildNameField(context) : _buildWalletName(context),
            ),
          ),
          Observer(builder: (_) => _buildActions(context)),
        ],
      ),
    ),
  );

  Widget _buildNameField(BuildContext context) => BaseTextFormField(
    key: const ValueKey("wallet_edit_page_name_input_key"),
    controller: _labelController,
    hintText: S.of(context).wallet_list_wallet_name,
    validator: WalletNameValidator(),
  );

  Widget _buildWalletName(BuildContext context) => Text(
    pageArguments.editingWallet.name,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );

  Widget _buildActions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLoading = walletEditViewModel.state is WalletEditRenamePending ||
        walletEditViewModel.state is WalletEditDeletePending;

    final deleteButton = LoadingPrimaryButton(
      key: const ValueKey("wallet_edit_page_delete_button_key"),
      isDisabled: isLoading,
      onPressed: () => _removeWallet(context),
      text: S.of(context).delete,
      color: colors.errorContainer,
      textColor: colors.onErrorContainer,
    );

    final saveButton = LoadingPrimaryButton(
      key: const ValueKey("wallet_edit_page_save_button_key"),
      isDisabled: isLoading || walletEditViewModel.newName.trim().isEmpty,
      onPressed: () => _renameGroup(context),
      text: S.of(context).save,
      color: colors.primary,
      textColor: colors.onPrimary,
    );

    return Row(
      children: [
        if (_canDelete) Expanded(child: deleteButton),
        if (_canDelete && _canRename) const SizedBox(width: 16),
        if (_canRename) Expanded(child: saveButton),
      ],
    );
  }

  Future<void> _renameGroup(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final confirmed = SettingsStoreBase.walletPasswordDirectInput
          ? await _renameWithPassword(context)
          : await _rename();

      if (confirmed && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      printV("Failed to rename wallet group: $e");
    } finally {
      walletEditViewModel.resetState();
    }
  }

  Future<bool> _rename() async {
    await walletEditViewModel.renameGroup(pageArguments.walletGroupKey);
    return true;
  }

  Future<bool> _renameWithPassword(BuildContext context) async {
    var confirmed = false;

    await Navigator.of(context).pushNamed(
      Routes.walletUnlockLoadable,
      arguments: WalletUnlockArguments(
        authPasswordHandler: (_) => walletEditViewModel.renameGroup(pageArguments.walletGroupKey),
        callback: (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) return;
          auth.close();
          confirmed = true;
        },
        walletName: pageArguments.editingWallet.name,
        walletType: pageArguments.editingWallet.type,
      ),
    );

    return confirmed;
  }

  void _removeWallet(BuildContext context) {
    pageArguments.authService!.authenticateAction(
      context,
      onAuthSuccess: (isAuthenticatedSuccessfully) async {
        if (isAuthenticatedSuccessfully) {
          await _confirmAndRemove(context);
        }
      },
      conditionToDetermineIfToUse2FA: false,
    );
  }

  Future<void> _confirmAndRemove(BuildContext context) async {
    final wallet = pageArguments.editingWallet;
    var confirmed = false;

    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertRightActionButtonKey: const ValueKey("wallet_edit_page_confirm_delete_button_key"),
        alertLeftActionButtonKey: const ValueKey("wallet_edit_page_cancel_delete_button_key"),
        alertTitle: S.of(context).delete_wallet,
        alertContent: S.of(context).delete_wallet_confirm_message(wallet.name),
        leftButtonText: S.of(context).cancel,
        rightButtonText: S.of(context).delete,
        actionLeftButton: () => Navigator.of(dialogContext).pop(),
        actionRightButton: () {
          confirmed = true;
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    if (!confirmed || !context.mounted) return;

    Navigator.of(context).pop();

    try {
      _showProgress(context, S.of(context).wallet_list_removing_wallet(wallet.name));
      await walletEditViewModel.remove(wallet);
      await _hideProgress();
    } catch (e) {
      if (!context.mounted) return;
      _showProgress(context, S.of(context).wallet_list_failed_to_remove(wallet.name, e.toString()));
    }
  }

  void _showProgress(BuildContext context, String text) {
    _progressBar = createBar<void>(text, context, duration: null)..show(context);
  }

  Future<void> _hideProgress() async {
    try {
      await Future.delayed(const Duration(milliseconds: 250));

      final bar = _progressBar;
      final barRoute = bar?.flushbarRoute;

      if (bar != null && barRoute != null && barRoute.isActive) {
        if (bar.isShowing()) {
          await bar.dismiss();
        } else {
          barRoute.navigator?.removeRoute(barRoute);
        }
      }
    } catch (e) {
      printV(e);
    }
    _progressBar = null;
  }
}