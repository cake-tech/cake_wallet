import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/src/painting/gradient.dart';
import 'package:meta/meta.dart';

part 'card_customizer_event.dart';

part 'card_customizer_state.dart';

class CardCustomizerBloc extends Bloc<CardCustomizerEvent, CardCustomizerState> {
  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;

  CardCustomizerBloc(this.dashboardViewModel, this.accountListViewModel)
      : super(CardCustomizerInitial(0, 0, [CardDesign.genericDefault], "", 0)) {
    on<_Init>((event, emit) async {
      printV("init called");
      // await dashboardViewModel.loadCardDesigns();
      await dashboardViewModel.designsLoaded;
      final account = accountListViewModel?.accounts.where((e) => e.isSelected).first ?? null;
      final accountName = account?.label ?? "";
      final accountIndex = account?.id ?? 0;
      final availableDesigns = _initAvailableDesigns();
      final selectedDesign = _initSelectedDesign(accountIndex);
      final selectedColor = _initSelectedColor(accountIndex);

      emit(CardCustomizerInitial(
          selectedDesign, selectedColor, availableDesigns, accountName, accountIndex));
    });

    on<CardDesignSelected>(_onDesignSelected);
    on<ColorSelected>(_onColorSelected);
    on<DesignSaved>(_onDesignSaved);

    add(_Init());
  }

  List<CardDesign> _initAvailableDesigns() {
    final List<CardDesign> ret = List<CardDesign>.empty(growable: true);

    ret.add(CardDesign.forCurrency(dashboardViewModel.wallet.currency));

    if (CardDesign.specialDesignsForCurrencies[dashboardViewModel.wallet.currency] != null)
      ret.add(CardDesign.forCurrencySpecial(dashboardViewModel.wallet.currency));

    return ret;
  }

  int _initSelectedDesign(int accountIndex) {
    final currentDesign = dashboardViewModel.cardDesigns[accountIndex];

    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgIcon)
      return 0;
    else if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull)
      return 1;
    else
      return 0;
  }

  int _initSelectedColor(int accountIndex) {
    final currentDesign = dashboardViewModel.cardDesigns[accountIndex];

    int ret = CardDesign.allGradients.indexOf(currentDesign.gradient);
    return ret != -1 ? ret : 0;
  }

  void _onDesignSelected(CardDesignSelected event, Emitter<CardCustomizerState> emit) {
    emit(CardCustomizerInitial(event.newDesignIndex, state.selectedColorIndex,
        state.availableDesigns, state.accountName, state.accountIndex));
  }

  void _onColorSelected(ColorSelected event, Emitter<CardCustomizerState> emit) {
    emit(CardCustomizerInitial(state.selectedDesignIndex, event.newColorIndex,
        state.availableDesigns, state.accountName, state.accountIndex));
  }

  void _onDesignSaved(DesignSaved event, Emitter<CardCustomizerState> emit) {
    dashboardViewModel.cardDesigns[state.accountIndex] = state.selectedDesign;

    for (int i = 0; i < dashboardViewModel.cardDesigns.length; i++) {
      BalanceCardStyleSettings.fromCardDesign(
              dashboardViewModel.wallet.walletInfo.internalId,
              (dashboardViewModel.balanceViewModel.hasAccounts ? i : -1),
              dashboardViewModel.cardDesigns[i])
          .insert();
    }
  }
}
