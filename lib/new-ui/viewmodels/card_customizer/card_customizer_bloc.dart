import 'package:bloc/bloc.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import "package:cw_core/balance_card_style_settings.dart";
import 'package:cw_core/card_design.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import "package:cw_core/wallet_type.dart";
import 'package:flutter/src/painting/gradient.dart';
import 'package:meta/meta.dart';

part 'card_customizer_event.dart';
part 'card_customizer_state.dart';

class CardCustomizerBloc extends Bloc<CardCustomizerEvent, CardCustomizerState> {
  final WalletBase _wallet;
  final bool lightningMode;

  CardCustomizerBloc(this._wallet, {this.lightningMode = false})
      : super(CardCustomizerNotLoaded(0, 0, [CardDesign.genericDefault], [], "", -1, 0)) {

    on<_Init>(_init);
    on<CardDesignSelected>(_onDesignSelected);
    on<ColorSelected>(_onColorSelected);
    on<DesignSaved>(_onDesignSaved);
    on<AccountNameChanged>(_onAccountNameChanged);


    add(_Init());
  }

  List<Gradient> _updateAvailableColors(CardDesign currentDesign) {
    final list = List<Gradient>.from(CardDesign.allGradients, growable: true);
    if (CardDesign.specialDesignsForCurrencies[_wallet.currency] != null) {
      list.add(CardDesign.specialDesignsForCurrencies[_wallet.currency]!.gradient);
    }
    return list;
  }

  Future<BalanceCardStyleSettings?> _loadCurrentDesignSettings(int accountIndex) async {
    return (await BalanceCardStyleSettings.get(_wallet.walletInfo.internalId, accountIndex));
  }

  List<CardDesign> _initAvailableDesigns({bool lightningMode = false}) {
    final List<CardDesign> ret = List<CardDesign>.empty(growable: true);
    final curr = lightningMode ? CryptoCurrency.btcln : _wallet.currency;

    ret.add(CardDesign.forCurrencyIcon(curr));

    if (CardDesign.specialDesignsForCurrencies[curr] != null)
      ret.add(CardDesign.forCurrencySpecial(curr));

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
    if(ret == -1) {
      // special design with its own color. select last color in list.
      return CardDesign.allGradients.length;
    } else if (ret == -1) {
      // no color selected, select default.
      return 0;
    } else {
      // select whatever's selected.
      return ret;
    }
  }

  void _init(_Init event, Emitter<CardCustomizerState> emit) async {
    late final account;
    if (_wallet.type == WalletType.monero) {
      account = monero!.getCurrentAccount(_wallet);
    } else if (_wallet.type == WalletType.wownero) {
      account = wownero!.getCurrentAccount(_wallet);
    } else {
      account = null;
    }
    final accountName = (account?.label ?? "") as String;
    late final int accountIndex;
    if(account != null) {
      accountIndex = account.id as int;
    } else if(lightningMode) {
      accountIndex = 0;
    } else {
      accountIndex = -1;
    }
    final currentDesignSettings = await _loadCurrentDesignSettings(accountIndex);
    final currentDesign = CardDesign.fromStyleSettings(currentDesignSettings, lightningMode ? CryptoCurrency.btcln : _wallet.currency);
    final availableDesigns = _initAvailableDesigns();
    final availableColors = _updateAvailableColors(currentDesign);
    final selectedDesign = _initSelectedDesign(currentDesign);
    final selectedColor = _initSelectedColor(currentDesign);

    emit(CardCustomizerInitial(selectedDesign, selectedColor, availableDesigns, availableColors,
        accountName, accountIndex, currentDesignSettings?.cardOrder ?? 0));
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

  void _onAccountNameChanged(AccountNameChanged event, Emitter<CardCustomizerState> emit) {
    emit(state.copyWith(accountName: event.newAccountName));
  }

  void _onDesignSaved(DesignSaved event, Emitter<CardCustomizerState> emit) {
    BalanceCardStyleSettings.fromCardDesign(
            _wallet.walletInfo.internalId, state.accountIndex, state.cardOrder, state.selectedDesign)
        .insert()
        .then((value) {
      emit(CardCustomizerSaved(state.selectedDesignIndex, state.selectedColorIndex,
          state.availableDesigns, state.availableColors, state.accountName, state.accountIndex, state.cardOrder));
    });
    saveAccountName();
  }

  Future<void> saveAccountName() async {
    if (_wallet.type == WalletType.monero) {
      await saveMoneroAccountName();
    }

    if (_wallet.type == WalletType.wownero) {
      await saveWowneroAccountName();
    }
  }

  Future<void> saveMoneroAccountName() async {
    final MoneroAccountList moneroAccountList = monero!.getAccountList(_wallet);
    await moneroAccountList.setLabelAccount(_wallet,
        accountIndex: state.accountIndex, label: state.accountName);

    await _wallet.save();
  }

  Future<void> saveWowneroAccountName() async {
    final WowneroAccountList wowneroAccountList = wownero!.getAccountList(_wallet);
    await wowneroAccountList.setLabelAccount(_wallet,
        accountIndex: state.accountIndex, label: state.accountName);

    await _wallet.save();
  }
}
