import 'package:bloc/bloc.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import "package:cw_core/balance_card_style_settings.dart";
import 'package:cw_core/card_design.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import "package:cw_core/wallet_type.dart";
import 'package:flutter/src/painting/gradient.dart';
import 'package:meta/meta.dart';

part 'card_customizer_event.dart';
part 'card_customizer_state.dart';

class CardCustomizerBloc extends Bloc<CardCustomizerEvent, CardCustomizerState> {
  final WalletBase _wallet;

  CardCustomizerBloc(this._wallet)
      : super(CardCustomizerInitial(0, 0, [CardDesign.genericDefault], [], "", -1)) {
    on<_Init>((event, emit) async {
      late final account;
      if (_wallet.type == WalletType.monero) {
        account = monero!.getCurrentAccount(_wallet);
      } else if (_wallet.type == WalletType.wownero) {
        account = wownero!.getCurrentAccount(_wallet);
      } else {
        account = null;
      }
      final currentDesign = await _loadCurrentDesign();
      final accountName = (account?.label ?? "") as String;
      final accountIndex = account == null ? -1 : account.id as int;
      final availableDesigns = _initAvailableDesigns();
      final availableColors = _updateAvailableColors(currentDesign);
      final selectedDesign = _initSelectedDesign(currentDesign);
      final selectedColor = _initSelectedColor(currentDesign);

      emit(CardCustomizerInitial(selectedDesign, selectedColor, availableDesigns, availableColors,
          accountName, accountIndex));
    });

    on<CardDesignSelected>(_onDesignSelected);
    on<ColorSelected>(_onColorSelected);
    on<DesignSaved>(_onDesignSaved);

    add(_Init());
  }

  List<Gradient> _updateAvailableColors(CardDesign currentDesign) {
    final list = List<Gradient>.from(CardDesign.allGradients, growable: true);
    printV(currentDesign.backgroundType);
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull &&
        CardDesign.specialDesignsForCurrencies[_wallet.currency] != null) {
      list.add(CardDesign.specialDesignsForCurrencies[_wallet.currency]!.gradient);
    }
    return list;
  }

  Future<CardDesign> _loadCurrentDesign() async {
    final setting =
        await BalanceCardStyleSettings.get(_wallet.walletInfo.internalId, state.accountIndex);
    return CardDesign.fromStyleSettings(setting, _wallet.currency);
  }

  List<CardDesign> _initAvailableDesigns() {
    final List<CardDesign> ret = List<CardDesign>.empty(growable: true);

    ret.add(CardDesign.forCurrency(_wallet.currency));

    if (CardDesign.specialDesignsForCurrencies[_wallet.currency] != null)
      ret.add(CardDesign.forCurrencySpecial(_wallet.currency));

    return ret;
  }

  int _initSelectedDesign(CardDesign currentDesign) {
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgIcon)
      return 0;
    else if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull)
      return 1;
    else
      return 0;
  }

  int _initSelectedColor(CardDesign currentDesign) {
    int ret = CardDesign.allGradients.indexOf(currentDesign.gradient);
    return (ret != -1 || currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull)
        ? ret
        : 0;
  }

  void _onDesignSelected(CardDesignSelected event, Emitter<CardCustomizerState> emit) {
    final newColors = _updateAvailableColors(state.availableDesigns[event.newDesignIndex]);
    late final int newColorIndex;
    if (newColors.length < state.availableColors.length) {
      newColorIndex = 0;
    } else {
      newColorIndex = state.selectedColorIndex;
    }

    emit(state.copyWith(
        selectedDesignIndex: event.newDesignIndex,
        availableColors: newColors,
        selectedColorIndex: newColorIndex));
  }

  void _onColorSelected(ColorSelected event, Emitter<CardCustomizerState> emit) {
    emit(state.copyWith(selectedColorIndex: event.newColorIndex));
  }

  void _onDesignSaved(DesignSaved event, Emitter<CardCustomizerState> emit) {
    BalanceCardStyleSettings.fromCardDesign(
            _wallet.walletInfo.internalId, state.accountIndex, state.selectedDesign)
        .insert()
        .then((value) {
      emit(CardCustomizerSaved(state.selectedDesignIndex, state.selectedColorIndex,
          state.availableDesigns, state.availableColors, state.accountName, state.accountIndex));
    });
  }
}
