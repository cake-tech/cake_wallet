import 'dart:math';

import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';

part 'monero_account_edit_or_create_view_model.g.dart';

class MoneroAccountEditOrCreateViewModel = MoneroAccountEditOrCreateViewModelBase
    with _$MoneroAccountEditOrCreateViewModel;

abstract class MoneroAccountEditOrCreateViewModelBase with Store {
  MoneroAccountEditOrCreateViewModelBase(this._moneroAccountList,
      {required WalletBase wallet, AccountListItem? accountListItem})
      : state = InitialExecutionState(),
        isEdit = accountListItem != null,
        label = accountListItem?.label ?? '',
        _accountListItem = accountListItem,
        _wallet = wallet;

  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

  final MoneroAccountList _moneroAccountList;
  final AccountListItem? _accountListItem;
  final WalletBase _wallet;

  Future<List<Gradient>> _getUsableCardGradients() async {
    final List<Gradient> ret = List<Gradient>.from(CardDesign.allGradients);
    final designs = (await BalanceCardStyleSettings.getAll(_wallet.walletInfo.internalId))
        .map((item) => CardDesign.fromStyleSettings(item, _wallet.currency));
    for (final design in designs) {
      ret.remove(design.gradient);
    }
    return ret.isNotEmpty ? ret : CardDesign.allGradients;
  }

  Future<void> _saveRandomCardDesign() async {
    final gradients = await _getUsableCardGradients();

    await BalanceCardStyleSettings.fromCardDesign(
            walletInfoId: _wallet.walletInfo.internalId,
            accountIndex: _moneroAccountList.accounts.length,
            cardOrder: _moneroAccountList.accounts.length,
            design: CardDesign.specialDesignsForCurrencies[_wallet.currency]!
                .withGradient(gradients[Random().nextInt(gradients.length)]))
        .insert();
  }

  Future<void> save() async {
    await _saveRandomCardDesign();
    if (_wallet.type == WalletType.monero) {
      await saveMonero();
    }
  }

  Future<void> saveMonero() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _moneroAccountList.setLabelAccount(_wallet,
            accountIndex: _accountListItem.id, label: label);
      } else {
        await _moneroAccountList.addAccount(_wallet, label: label);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
