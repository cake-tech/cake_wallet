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
  final bool displaySats;

  CardCustomizerBloc(this._wallet, {this.lightningMode = false, this.displaySats = false})
      : super(CardCustomizerNotLoaded(
            0, 0, [CardDesign.genericDefault], [], "", -1, displaySats, 0)) {
    on<_Init>(_init);
    on<CardDesignSelected>(_onDesignSelected);
    on<ColorSelected>(_onColorSelected);
    on<IconStyleSelected>(_onIconStyleSelected);
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

    ret.add(CardDesign.gradientOnlyDesign);
    ret.add(CardDesign.forCurrencyIcon(curr));

    if (CardDesign.specialDesignsForCurrencies[curr] != null)
      ret.add(CardDesign.forCurrencySpecial(curr));

    return ret;
  }

  int _initSelectedDesign(CardDesign currentDesign) {
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.gradientOnly) {
      return 0;
    }
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgIcon) {
      return 1;
    }
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull) {
      return 2;
    }
    return 0;
  }

  int _initSelectedIconIndex(
    BalanceCardStyleSettings? settings,
    List<CardIconPath> availableIconPaths,
  ) {
    if (settings == null || availableIconPaths.isEmpty) return 0;
    if (settings.iconStyleIndex >= availableIconPaths.length) return 0;
    return settings.iconStyleIndex;
  }

  int _initSelectedColor(CardDesign currentDesign) {
    final ret = CardDesign.allGradients.indexOf(currentDesign.gradient);
    return ret == -1 ? CardDesign.allGradients.length : ret;
  }

  void _init(_Init event, Emitter<CardCustomizerState> emit) async {
    final accountInfo = await _getCurrentAccountInfo();
    final accountName = accountInfo.accountName;
    final accountIndex = accountInfo.accountIndex;
    final curr = lightningMode ? CryptoCurrency.btcln : _wallet.currency;
    final currentDesignSettings = await _loadCurrentDesignSettings(accountIndex);
    final currentDesign = CardDesign.fromStyleSettings(currentDesignSettings, curr);
    final availableDesigns = _initAvailableDesigns(lightningMode: lightningMode);
    final availableColors = _updateAvailableColors(currentDesign);
    final selectedDesignIndex = _initSelectedDesign(currentDesign);
    final selectedColor = _initSelectedColor(currentDesign);
    final availableIconPaths = CardDesign.iconPathsForWalletType(curr);
    final selectedIconIndex = _initSelectedIconIndex(currentDesignSettings, availableIconPaths);

    emit(CardCustomizerInitial(
        selectedDesignIndex,
        selectedColor,
        availableDesigns,
        availableColors,
        accountName,
        accountIndex,
        displaySats,
        currentDesignSettings?.cardOrder ?? 0,
        availableIconPaths: availableIconPaths,
        selectedIconIndex: selectedIconIndex));
  }

  Future<({String accountName, int accountIndex})> _getCurrentAccountInfo() async {
    if (lightningMode) {
      return (accountName: "", accountIndex: -2);
    }

    if (_wallet.type == WalletType.monero) {
      final account = monero!.getCurrentAccount(_wallet);
      return (accountName: account.label, accountIndex: account.id);
    }

    if (_wallet.type == WalletType.wownero) {
      final account = wownero!.getCurrentAccount(_wallet);
      return (accountName: account.label, accountIndex: account.id);
    }

    if (_wallet.type == WalletType.bitcoin) {
      final selectedAccountIndex = _wallet.walletInfo.selectedAccount ?? 0;
      final accounts = await _wallet.walletInfo.getAccounts();
      final account =
          accounts.where((account) => account.accountIndex == selectedAccountIndex).firstOrNull;

      return (
        accountName: account?.label ?? "",
        accountIndex: selectedAccountIndex,
      );
    }

    return (accountName: "", accountIndex: -1);
  }

  void _onDesignSelected(CardDesignSelected event, Emitter<CardCustomizerState> emit) {
    final newColors = _updateAvailableColors(state.availableDesigns[event.newDesignIndex]);
    late final int newColorIndex;
    if (newColors.isEmpty) {
      newColorIndex = 0;
    } else if (newColors.length < state.availableColors.length) {
      newColorIndex = 0;
    } else {
      newColorIndex = state.selectedColorIndex.clamp(0, newColors.length - 1);
    }

    emit(state.copyWith(
        selectedDesignIndex: event.newDesignIndex,
        availableColors: newColors,
        selectedColorIndex: newColorIndex));
  }

  void _onColorSelected(ColorSelected event, Emitter<CardCustomizerState> emit) {
    emit(state.copyWith(selectedColorIndex: event.newColorIndex));
  }

  void _onIconStyleSelected(IconStyleSelected event, Emitter<CardCustomizerState> emit) {
    emit(state.copyWith(selectedIconIndex: event.iconIndex));
  }

  void _onAccountNameChanged(AccountNameChanged event, Emitter<CardCustomizerState> emit) {
    emit(state.copyWith(accountName: event.newAccountName));
  }

  Future<void> _onDesignSaved(DesignSaved event, Emitter<CardCustomizerState> emit) async {
    await BalanceCardStyleSettings.fromCardDesign(
            walletInfoId: _wallet.walletInfo.internalId,
            accountIndex: state.accountIndex,
            cardOrder: state.cardOrder,
            design: state.selectedDesign,
            iconStyleIndex: state.selectedIconIndex,
            gradientIndexOverride: state.selectedColorIndex)
        .insert();

    await saveAccountName();

    emit(CardCustomizerSaved(
        state.selectedDesignIndex,
        state.selectedColorIndex,
        state.availableDesigns,
        state.availableColors,
        state.accountName,
        state.accountIndex,
        state.displaySats,
        state.cardOrder,
        availableIconPaths: state.availableIconPaths,
        selectedIconIndex: state.selectedIconIndex));
  }

  Future<void> saveAccountName() async {
    if (_wallet.type == WalletType.monero) {
      await saveMoneroAccountName();
    }

    if (_wallet.type == WalletType.wownero) {
      await saveWowneroAccountName();
    }
    if (_wallet.type == WalletType.bitcoin && !lightningMode) {
      await saveBitcoinAccountName();
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

  Future<void> saveBitcoinAccountName() async {
    await _wallet.walletInfo.renameAccount(
      accountIndex: state.accountIndex,
      label: state.accountName,
    );
  }
}
