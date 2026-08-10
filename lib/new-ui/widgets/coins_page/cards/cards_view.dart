import 'dart:math';

import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import 'balance_card.dart';

class CardsView extends StatefulWidget {
  const CardsView(
      {super.key,
      required this.dashboardViewModel,
      required this.lightningMode,
      required this.onCompactModeBackgroundCardsTapped,
      required this.onCustomizeTapped,
      this.actions,
      this.maxVisibleCards = 5,
      this.allowCompactMode = true});

  final DashboardViewModel dashboardViewModel;
  final VoidCallback onCompactModeBackgroundCardsTapped;
  final VoidCallback onCustomizeTapped;
  final bool lightningMode;
  final List<BalanceCardAction>? actions;

  final int? maxVisibleCards;
  final bool allowCompactMode;

  _CardsViewState createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  late int _selectedIndex;
  bool isFirstBuild = true;

  static const Duration animDuration = Duration(milliseconds: 200);
  static const int compactModeTreshold = 6;

  int _cardsToRender(int numCards) {
    final limit = widget.maxVisibleCards;
    if (limit == null) {
      return numCards - 1;
    }

    return min(numCards - 1, limit);
  }

  final List<ReactionDisposer> _disposers = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _currentSelectedVisualIndex();

    _disposers.add(reaction(
      (_) => widget.dashboardViewModel.cardOrder.values.toList(),
      (_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = _currentSelectedVisualIndex();
        });
      },
    ));

    _disposers.add(reaction(
      (_) => widget.dashboardViewModel.accountListViewModel?.selectedAccount?.id,
      (_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = _currentSelectedVisualIndex();
        });
      },
    ));

    _disposers.add(reaction(
      (_) => widget.dashboardViewModel.accountListViewModel?.accounts.length,
      (_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = _currentSelectedVisualIndex();
        });
      },
    ));
  }

  @override
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CardsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lightningMode != widget.lightningMode ||
        oldWidget.dashboardViewModel.accountListViewModel?.accounts.length !=
            widget.dashboardViewModel.accountListViewModel?.accounts.length ||
        oldWidget.dashboardViewModel.cardDesigns.length !=
            widget.dashboardViewModel.cardDesigns.length) {
      _selectedIndex = _currentSelectedVisualIndex();
    }
  }

  Widget _buildCard(int visualIndex, int realIndex, int numCards, double parentWidth,
      bool compactMode, double overlapAmount) {
    final accountListViewModel = widget.dashboardViewModel.accountListViewModel;

    final baseTop = overlapAmount * (numCards - 1);
    final scaleFactor = compactMode ? 1 : 0.96;

    final howFarBehind = (_selectedIndex - visualIndex + numCards) % numCards;
    final scale = pow(scaleFactor, howFarBehind).toDouble();

    final top = baseTop - (howFarBehind * overlapAmount);

    final left = (parentWidth - effectiveCardWidth) / 2.0;

    final isSelected = _selectedIndex == visualIndex;
    final accounts = accountListViewModel?.accounts;
    final cardLabel = (accounts != null && realIndex < accounts.length)
        ? accounts[realIndex].label
        : S.of(context).balance;

    void onCardTap() {
      if (compactMode && visualIndex != 0) {
        widget.onCompactModeBackgroundCardsTapped();
      } else if (!compactMode) {
        setState(() {
          _selectedIndex = visualIndex;
          if (!widget.lightningMode &&
              accountListViewModel != null &&
              realIndex < accountListViewModel.accounts.length) {
            accountListViewModel.select(accountListViewModel.accounts[realIndex]);
          }
        });
      }
    }

    void onCardLongPress() {
      if (_selectedIndex == visualIndex) {
        widget.dashboardViewModel.balanceViewModel.switchBalanceValue();
      }
      HapticFeedback.heavyImpact();
    }

    return AnimatedPositioned(
      key: ValueKey("$visualIndex $realIndex"),
      duration: animDuration,
      curve: Curves.easeOut,
      top: top,
      left: left,
      child: AnimatedScale(
        duration: animDuration,
        curve: Curves.easeOut,
        scale: scale,
        // The card is the tap target; the balances and the card's own buttons stay
        // reachable as children of this node.
        child: Semantics(
          button: true,
          selected: isSelected,
          label: cardLabel,
          hint: isSelected
              ? (widget.dashboardViewModel.balanceViewModel.displayMode ==
              BalanceDisplayMode.hiddenBalance
              ? S.of(context).long_press_show_balance
              : S.of(context).long_press_hide_balance)
              : null,
          onTap: onCardTap,
          onLongPress: isSelected ? onCardLongPress : null,
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: onCardTap,
            onLongPress: onCardLongPress,
            child: Observer(builder: (_) {
              if (!widget.lightningMode &&
                  realIndex >= (accountListViewModel?.accounts.length ?? 1)) {
                return Container();
              }

              final account = !widget.lightningMode &&
                  realIndex < (accountListViewModel?.accounts.length ?? 0)
                  ? accountListViewModel?.accounts[realIndex]
                  : null;

              // The second balance should always be the lightning balance
              final walletBalanceRecord = widget.dashboardViewModel.balanceViewModel
                  .getMainBalanceRecord(widget.lightningMode);

              late final String walletBalance;
              late final String walletFiatBalance;
              if (widget.dashboardViewModel.mwebEnabled && widget.dashboardViewModel.hasMweb) {
                if (widget.dashboardViewModel.balanceViewModel.displayMode ==
                    BalanceDisplayMode.hiddenBalance) {
                  walletBalance = '●●●●●●';
                  walletFiatBalance = '●●●●●●';
                } else {
                  walletBalance = walletBalanceRecord?.combinedAvailableBalance ?? "0";
                  walletFiatBalance = walletBalanceRecord?.combinedFiatAvailableBalance ?? "0.00";
                }
              } else if (widget.dashboardViewModel.balanceViewModel.showCombinedBalance) {
                walletBalance = "";
                walletFiatBalance = widget.dashboardViewModel.balanceViewModel.combinedFiatBalance;
              } else {
                walletBalance = walletBalanceRecord?.availableBalance ?? "0";
                walletFiatBalance = walletBalanceRecord?.fiatAvailableBalance ?? "0.00";
              }

              // the card designs is empty if widget gets built before it loads.
              // should get populated before user sees anything
              final CardDesign cardDesign;
              if (widget.dashboardViewModel.cardDesigns.isEmpty) {
                cardDesign = CardDesign.genericDefault;
              } else if (widget.lightningMode) {
                cardDesign = widget.dashboardViewModel.cardDesigns.last;
              } else if (realIndex >= widget.dashboardViewModel.cardDesigns.length) {
                cardDesign = CardDesign.genericDefault;
              } else {
                cardDesign = widget.dashboardViewModel.cardDesigns[realIndex];
              }

              final String accountName;
              final String accountBalance;
              if (account == null) {
                accountName = "";
                accountBalance = "";
              } else {
                accountName = account.label;
                accountBalance = account.balance ?? "0.00";
              }

              final assetName = widget.dashboardViewModel.balanceViewModel.showCombinedBalance
                  ? ""
                  : walletBalanceRecord?.formattedAssetTitle ?? assetTitleFallback;

              return BalanceCard(
                width: effectiveCardWidth,
                accountName: accountName,
                accountBalance: accountBalance,
                designSwitchDuration: Duration(milliseconds: 150),
                assetName: assetName,
                capitalizeAssetName: _shouldCapitalizeAssetName(),
                balance: walletBalance,
                accountIndex: account?.id,
                fiatCurrencyTitle: walletBalanceRecord?.fiatCurrency?.title ??
                    widget.dashboardViewModel.settingsStore.fiatCurrency.title,
                fiatFirst: widget.dashboardViewModel.balanceViewModel.showCombinedBalance,
                fiatBalance: walletFiatBalance,
                selected: isSelected,
                onCustomizeTapped: isSelected ? widget.onCustomizeTapped : null,
                design: cardDesign,
                actions: widget.actions ?? [],
              );
            }),
          ),
        ),
      ),
    );
  }

  String get assetTitleFallback =>
      widget.dashboardViewModel.appStore.amountParsingProxy.getCryptoSymbol(
          widget.lightningMode ? CryptoCurrency.btcln : widget.dashboardViewModel.wallet.currency);

  bool _shouldCapitalizeAssetName() {
    if (widget.dashboardViewModel.wallet.type != WalletType.bitcoin) {
      return true;
    }

    switch (widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi) {
      case BitcoinAmountDisplayMode.satoshi:
        return false;
      case BitcoinAmountDisplayMode.satoshiForLightning:
        return !widget.lightningMode;
      case BitcoinAmountDisplayMode.bitcoin:
        return true;
      default:
        return true;
    }
  }

  double get effectiveCardWidth => min(MediaQuery.of(context).size.width * 0.878,
      responsiveLayoutUtil.shouldRenderMobileUI ? 768 : 512);

  double _getBoxHeight(int numCards, double overlapAmount) {
    return
        /* height of initial card */
        (2 / 3.2) * (effectiveCardWidth) +
            /* height of bg card * amount of bg cards */
            overlapAmount * ((numCards) - 1);
  }

  int _visibleCardsCount() {
    if (widget.lightningMode) {
      return 1;
    }

    return widget.dashboardViewModel.accountListViewModel?.accounts.length ??
        widget.dashboardViewModel.cardDesigns.length;
  }

  int _realIndexForVisualIndex(int visualIndex, int numCards) {
    if (widget.lightningMode) {
      return widget.dashboardViewModel.cardDesigns.length - 1;
    }

    if (widget.dashboardViewModel.cardOrder.length != numCards ||
        !widget.dashboardViewModel.cardOrder.containsKey(visualIndex)) {
      return visualIndex;
    }

    return widget.dashboardViewModel.cardOrder[visualIndex] ?? visualIndex;
  }

  int _currentSelectedVisualIndex() {
    final numCards = _visibleCardsCount();

    if (numCards <= 1 || widget.lightningMode) {
      return 0;
    }

    final accountListViewModel = widget.dashboardViewModel.accountListViewModel;
    final selectedAccount = accountListViewModel?.selectedAccount;
    final accounts = accountListViewModel?.accounts;

    if (selectedAccount == null || accounts == null || accounts.isEmpty) {
      return max(0, numCards - 1);
    }

    final selectedRealIndex = accounts.indexWhere(
      (account) => account.id == selectedAccount.id,
    );

    if (selectedRealIndex < 0) {
      return max(0, numCards - 1);
    }

    final visualIndex = widget.dashboardViewModel.cardOrder.entries
        .where((entry) => entry.value == selectedRealIndex)
        .map((entry) => entry.key)
        .firstOrNull;

    if (visualIndex == null || visualIndex < 0 || visualIndex >= numCards) {
      return selectedRealIndex.clamp(0, numCards - 1);
    }

    return visualIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final parentWidth = MediaQuery.of(context).size.width;
      final children = <Widget>[];

      int numCards = _visibleCardsCount();

      if (numCards == 0) numCards = 1;

      if (_selectedIndex >= numCards) {
        _selectedIndex = _currentSelectedVisualIndex();
      }

      final bool compactMode = widget.allowCompactMode && numCards >= compactModeTreshold;
      final double overlapAmount = compactMode ? 5.0 : 46.0;
      for (int i = _cardsToRender(numCards); i >= 0; i--) {
        int visualIndex = (_selectedIndex - i + numCards) % numCards;

        final realIndex = _realIndexForVisualIndex(visualIndex, numCards);

        children.add(
            _buildCard(visualIndex, realIndex, numCards, parentWidth, compactMode, overlapAmount));
      }

      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        height: _getBoxHeight(numCards, overlapAmount),
        child: SizedBox(
          key: ValueKey(_getBoxHeight(numCards, overlapAmount)),
          width: double.infinity,
          height: _getBoxHeight(numCards, overlapAmount),
          child: Stack(alignment: Alignment.center, children: children),
        ),
      );
    });
  }
}
