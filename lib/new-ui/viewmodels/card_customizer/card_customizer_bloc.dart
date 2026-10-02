import 'package:bloc/bloc.dart';
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/utils/stable_balance_card_design.dart";
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

  /// Cached at `_init` time - whether Stable Balance is actually on for this wallet right now.
  /// Determines which persisted card style slot loads/saves (a separate style per on/off state,
  /// see [_accountIndexFor]) and which of Lightning's two full-graphic looks (bolt vs $) is
  /// suggested by default the first time each slot is ever customized.
  bool _stableBalanceActive = false;

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

  /// Same source the home balance card reads, so the two never disagree.
  Future<bool> _isStableBalanceActive() async =>
      lightningMode && (bitcoin?.isStableBalanceActive(_wallet) ?? false);

  List<CardDesign> _initAvailableDesigns({
    bool lightningMode = false,
    bool stableBalanceActive = false,
  }) {
    final List<CardDesign> ret = List<CardDesign>.empty(growable: true);
    final curr = lightningMode ? CryptoCurrency.btcln : _wallet.currency;

    ret.add(CardDesign.gradientOnlyDesign);
    ret.add(CardDesign.forCurrencyIcon(curr));

    if (CardDesign.specialDesignsForCurrencies[curr] != null)
      ret.add(CardDesign.forCurrencySpecial(
        curr,
        specialDesignOverride: StableBalanceCardDesign.specialDesignOverride(
          curr,
          stableBalanceActive: stableBalanceActive,
        ),
      ));

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
    List<CardIconPath> availableIconPaths, {
    int defaultIndex = 0,
  }) {
    if (availableIconPaths.isEmpty) return 0;
    final fallback = defaultIndex.clamp(0, availableIconPaths.length - 1);
    if (settings == null) return fallback;
    if (settings.iconStyleIndex >= availableIconPaths.length) return fallback;
    return settings.iconStyleIndex;
  }

  /// The icon-style choices for a given "Card style" index - a different set depending on which
  /// style is selected, not a single fixed list:
  /// - The flat solid-color style (0) has nowhere to put an icon at all.
  /// - The small-icon style (1) offers the usual per-currency icon family.
  /// - The full-graphic style (2) only ever offers a second look for Lightning, and only while
  ///   Stable Balance is actually on - the $ coin design has no reason to exist as a choice on a
  ///   regular (non-stable) Lightning wallet. Off Stable Balance (or for any other currency),
  ///   there's exactly one full-graphic look, so this returns a single-entry list; the caller
  ///   hides the picker row entirely rather than show a "choice" of one (see
  ///   `card_customizer.dart#_showIconStylePanel`).
  ///
  /// Each entry's [CardIconPath.thumbnailPath] points at the small per-purpose icon glyph
  /// (bolt / $) rather than [CardIconPath.path] itself (the full card background), since the
  /// latter is illegible at the picker's ~48px thumbnail size - see [CardIconPath]'s doc comment.
  List<CardIconPath> _iconChoicesForDesignIndex(int designIndex, CryptoCurrency curr) {
    if (designIndex == 1) {
      return CardDesign.iconPathsForWalletType(
        curr,
        extraIconPaths: StableBalanceCardDesign.extraIconPaths(
          curr,
          stableBalanceActive: _stableBalanceActive,
        ),
      );
    }
    if (designIndex == 2 && curr == CryptoCurrency.btcln) {
      final bolt =
          CardIconPath(CardDesign.lnSpecial.imagePath, thumbnailPath: CardDesign.btcln.imagePath);
      if (!_stableBalanceActive) return [bolt];
      final dollar = CardIconPath(StableBalanceCardDesign.design.imagePath,
          thumbnailPath: StableBalanceCardDesign.iconPath);
      return [bolt, dollar];
    }
    return const [];
  }

  /// A separate persisted card style per Stable-Balance on/off state for the Lightning card, so
  /// switching the toggle swaps to (and remembers) its own look instead of sharing one style -
  /// `1` is otherwise never used as a Bitcoin-wallet card-style account index (Bitcoin only ever
  /// has the main card at `-1` and the Lightning card at `0`), so this can't collide.
  int _accountIndexFor({required bool stableBalanceActive}) => stableBalanceActive ? 1 : 0;

  int _initSelectedColor(CardDesign currentDesign) {
    final ret = CardDesign.allGradients.indexOf(currentDesign.gradient);
    return ret == -1 ? CardDesign.allGradients.length : ret;
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
    final curr = lightningMode ? CryptoCurrency.btcln : _wallet.currency;
    final stableBalanceActive = await _isStableBalanceActive();
    _stableBalanceActive = stableBalanceActive;
    late final int accountIndex;
    if (account != null) {
      accountIndex = account.id as int;
    } else if (lightningMode) {
      accountIndex = _accountIndexFor(stableBalanceActive: stableBalanceActive);
    } else {
      accountIndex = -1;
    }
    final currentDesignSettings = await _loadCurrentDesignSettings(accountIndex);
    final currentDesign = StableBalanceCardDesign.fromStyleSettings(
      currentDesignSettings,
      curr,
      stableBalanceActive: stableBalanceActive,
    );
    final availableDesigns = _initAvailableDesigns(
      lightningMode: lightningMode,
      stableBalanceActive: stableBalanceActive,
    );
    final availableColors = _updateAvailableColors(currentDesign);
    final selectedDesignIndex = _initSelectedDesign(currentDesign);
    final selectedColor = _initSelectedColor(currentDesign);
    final availableIconPaths = _iconChoicesForDesignIndex(selectedDesignIndex, curr);
    final defaultIconIndex =
        selectedDesignIndex == 2 &&
                StableBalanceCardDesign.appliesTo(curr, stableBalanceActive: stableBalanceActive)
            ? 1
            : 0;
    final selectedIconIndex = _initSelectedIconIndex(currentDesignSettings, availableIconPaths,
        defaultIndex: defaultIconIndex);

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

    final curr = lightningMode ? CryptoCurrency.btcln : _wallet.currency;
    final newIconPaths = _iconChoicesForDesignIndex(event.newDesignIndex, curr);
    final defaultIconIndex =
        event.newDesignIndex == 2 &&
                StableBalanceCardDesign.appliesTo(curr, stableBalanceActive: _stableBalanceActive)
            ? 1
            : 0;
    final newIconIndex =
        newIconPaths.isEmpty ? 0 : defaultIconIndex.clamp(0, newIconPaths.length - 1);

    emit(state.copyWith(
        selectedDesignIndex: event.newDesignIndex,
        availableColors: newColors,
        selectedColorIndex: newColorIndex,
        availableIconPaths: newIconPaths,
        selectedIconIndex: newIconIndex));
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

  void _onDesignSaved(DesignSaved event, Emitter<CardCustomizerState> emit) {
    BalanceCardStyleSettings.fromCardDesign(
            walletInfoId: _wallet.walletInfo.internalId,
            accountIndex: state.accountIndex,
            cardOrder: state.cardOrder,
            design: state.selectedDesign,
            iconStyleIndex: state.selectedIconIndex,
            gradientIndexOverride: state.selectedColorIndex)
        .insert()
        .then((value) {
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
