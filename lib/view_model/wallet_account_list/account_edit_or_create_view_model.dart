import "dart:math";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";
import "package:mobx/mobx.dart";

part "account_edit_or_create_view_model.g.dart";

class WalletAccountEditOrCreateViewModel = WalletAccountEditOrCreateViewModelBase
    with _$WalletAccountEditOrCreateViewModel;

abstract class WalletAccountEditOrCreateViewModelBase with Store {
  WalletAccountEditOrCreateViewModelBase(this._wallet, {AccountListItem? account})
      : _account = account,
        isEdit = account != null,
        label = account?.label ?? "",
        state = InitialExecutionState();

  final WalletBase _wallet;
  final AccountListItem? _account;
  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

  Future<void> save() async {
    try {
      state = IsExecutingState();

      final account = _account;
      if (account != null) {
        await _wallet.renameAccount(index: account.id, label: label);
      } else {
        final index = await _wallet.addAccount(label: label);
        await _saveRandomCardDesign(index);
        await _wallet.setCurrentAccount(index);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<void> _saveRandomCardDesign(int accountIndex) async {
    final design = CardDesign.specialDesignsForCurrencies[_wallet.currency];
    if (design == null) {
      return;
    }

    final gradients = await _usableCardGradients();
    await BalanceCardStyleSettings.fromCardDesign(
      walletInfoId: _wallet.walletInfo.internalId,
      accountIndex: accountIndex,
      cardOrder: _wallet.walletAccounts.length - 1,
      design: design.withGradient(gradients[Random().nextInt(gradients.length)]),
    ).insert();
  }

  Future<List<Gradient>> _usableCardGradients() async {
    final gradients = List<Gradient>.from(CardDesign.allGradients);
    final designs = (await BalanceCardStyleSettings.getAll(_wallet.walletInfo.internalId))
        .map((item) => CardDesign.fromStyleSettings(item, _wallet.currency));
    for (final design in designs) {
      gradients.remove(design.gradient);
    }
    return gradients.isNotEmpty ? gradients : CardDesign.allGradients;
  }
}
