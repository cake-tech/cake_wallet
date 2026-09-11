import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_edit_or_create_view_model.g.dart';

class BitcoinAccountEditOrCreateViewModel = BitcoinAccountEditOrCreateViewModelBase
    with _$BitcoinAccountEditOrCreateViewModel;

abstract class BitcoinAccountEditOrCreateViewModelBase
    with Store
    implements WalletAccountEditOrCreateViewModel {
  BitcoinAccountEditOrCreateViewModelBase({
    required WalletBase wallet,
    AccountListItem? accountListItem,
  })  : state = InitialExecutionState(),
        isEdit = accountListItem != null,
        label = accountListItem?.label ?? '',
        _accountListItem = accountListItem,
        _wallet = wallet;

  final bool isEdit;

  @observable
  ExecutionState state;

  @observable
  String label;

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

  Future<void> _saveRandomCardDesign(int accountIndex) async {
    final gradients = await _getUsableCardGradients();
    final accounts = await _wallet.walletInfo.getAccounts();

    await BalanceCardStyleSettings.fromCardDesign(
            walletInfoId: _wallet.walletInfo.internalId,
            accountIndex: accountIndex,
            cardOrder: accounts.length - 1,
            design: CardDesign.specialDesignsForCurrencies[_wallet.currency]!
                .withGradient(gradients[Random().nextInt(gradients.length)]))
        .insert();
  }

  Future<void> save() async {
    try {
      state = IsExecutingState();

      if (_accountListItem != null) {
        await _renameAccount(_accountListItem.id, label);
      } else {
        final accountIndex = await _createAccount(label);
        await _saveRandomCardDesign(accountIndex);
      }

      await _wallet.save();
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  Future<int> _createAccount(String label) async {
    final accounts = await _wallet.walletInfo.getAccounts();

    final nextIndex = accounts.isEmpty
        ? 0
        : accounts.map((e) => e.accountIndex).reduce((a, b) => a > b ? a : b) + 1;

    await _wallet.walletInfo.addAccount(
      accountIndex: nextIndex,
      label: label.isEmpty ? 'Account $nextIndex' : label,
    );

    await bitcoin!.setCurrentAccount(_wallet, nextIndex);

    return nextIndex;
  }

  Future<void> _renameAccount(int accountIndex, String label) async {
    await _wallet.walletInfo.renameAccount(
      accountIndex: accountIndex,
      label: label.isEmpty ? 'Account $accountIndex' : label,
    );
  }
}
