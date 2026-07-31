import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
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
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'balance_card.dart';

class CardsView extends StatefulWidget {
  const CardsView(
      {super.key,
      required this.dashboardViewModel,
      required this.accountListViewModel,
      required this.lightningMode,
      required this.onCompactModeBackgroundCardsTapped,
      required this.onCustomizeTapped});

  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;
  final VoidCallback onCompactModeBackgroundCardsTapped;
  final VoidCallback onCustomizeTapped;
  final bool lightningMode;

  @override
  _CardsViewState createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  late int _selectedIndex;
  bool isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.dashboardViewModel.cardOrder.length - 1;
    reaction(
        (_) => widget.dashboardViewModel.cardOrder.values.toList(),
        (_) => setState(() {
              _selectedIndex = widget.dashboardViewModel.cardOrder.length - 1;
            }));
  }

  static const Duration animDuration = Duration(milliseconds: 200);
  static const int compactModeTreshold = 4;
  static const int maxCards = 5;

  Widget _buildCard(int visualIndex, int realIndex, int numCards, double parentWidth,
      Map<int, int> order, bool compactMode, double overlapAmount) {
    final baseTop = overlapAmount * (numCards - 1);
    final scaleFactor = compactMode ? 1 : 0.96;

    final howFarBehind = (_selectedIndex - visualIndex + numCards) % numCards;
    final scale = pow(scaleFactor, howFarBehind).toDouble();

    final top = baseTop - (howFarBehind * overlapAmount);

    final left = (parentWidth - effectiveCardWidth) / 2.0;

    final isSelected = _selectedIndex == visualIndex;
    final accounts = widget.accountListViewModel?.accounts;
    final cardLabel = (accounts != null && realIndex < accounts.length)
        ? accounts[realIndex].label
        : S.of(context).balance;

    void onCardTap() {
      // printV(visualIndex);
      if (compactMode && visualIndex != 0) {
        widget.onCompactModeBackgroundCardsTapped();
      } else if (!compactMode) {
        setState(() {
          if (widget.accountListViewModel != null)
            widget.accountListViewModel!.select(widget.accountListViewModel!.accounts[realIndex]);
          _selectedIndex = visualIndex;
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
              if (realIndex >= (widget.accountListViewModel?.accounts.length ?? 1)) {
                return Container();
              }
              final account = widget.accountListViewModel?.accounts[realIndex];

              // The second balance should always be the lightning balance
              // printV(widget.dashboardViewModel.balanceViewModel.formattedBalances.first.availableBalance);
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
              if (widget.dashboardViewModel.cardDesigns.isEmpty ||
                  realIndex >= widget.dashboardViewModel.cardDesigns.length)
                cardDesign = CardDesign.genericDefault;
              else if (widget.lightningMode)
                cardDesign = widget.dashboardViewModel.cardDesigns[realIndex + 1];
              else
                cardDesign = widget.dashboardViewModel.cardDesigns[realIndex];

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

              final List<BalanceCardAction> actions = widget.lightningMode
                  ? [
                      BalanceCardAction(
                        label: S.current.bitcoin_lightning_deposit,
                        icon: Icons.arrow_downward,
                        onTap: depositToL2,
                      ),
                      BalanceCardAction(
                        label: S.current.bitcoin_lightning_withdraw,
                        icon: Icons.arrow_upward,
                        onTap: withdrawFromL2,
                      )
                    ]
                  : widget.dashboardViewModel.isEnabledTradeAction
                      ? [
                          BalanceCardAction(
                            label: S.current.buy,
                            icon: Icons.arrow_forward_ios_rounded,
                            iconSize: 12,
                            onTap: () => Navigator.of(context).pushNamed(Routes.buySellPage),
                          )
                        ]
                      : [];

              return BalanceCard(
                width: effectiveCardWidth,
                accountName: accountName,
                accountBalance: accountBalance,
                designSwitchDuration: Duration(milliseconds: 150),
                assetName: assetName,
                capitalizeAssetName: _shouldCapitalizeAssetName(),
                balance: walletBalance,
                fiatCurrencyTitle: walletBalanceRecord?.fiatCurrency?.title ??
                    widget.dashboardViewModel.settingsStore.fiatCurrency.title,
                fiatFirst: widget.dashboardViewModel.balanceViewModel.showCombinedBalance,
                fiatBalance: walletFiatBalance,
                selected: _selectedIndex == visualIndex,
                onCustomizeTapped: _selectedIndex == visualIndex ? widget.onCustomizeTapped : null,
                design: cardDesign,
                actions: actions,
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

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final parentWidth = MediaQuery.of(context).size.width;
      final children = <Widget>[];

      int numCards = widget.dashboardViewModel.wallet.type == WalletType.bitcoin
          ? 1
          : widget.dashboardViewModel.cardDesigns.length;
      if (numCards == 0) numCards = 1;

      if (_selectedIndex >= (numCards)) {
        _selectedIndex = 0;
      }

      Map<int, int> order = widget.dashboardViewModel.cardOrder.length != numCards
          ? Map<int, int>.fromEntries(
              List.generate(numCards, (i) => MapEntry(i, i)),
            )
          : widget.dashboardViewModel.cardOrder;

      for (int i = min(numCards - 1, maxCards); i >= 0; i--) {
        int visualIndex = (_selectedIndex - i + numCards) % numCards;
        if (order[visualIndex] == null) {
          order = Map<int, int>.fromEntries(
            List.generate(numCards, (i) => MapEntry(i, i)),
          );
        }
      }

      final bool compactMode = numCards >= compactModeTreshold;
      final double overlapAmount = compactMode ? 5.0 : 46.0;
      for (int i = min(numCards - 1, maxCards); i >= 0; i--) {
        int visualIndex = (_selectedIndex - i + numCards) % numCards;

        int realIndex = order[visualIndex]!;

        if (visualIndex == _selectedIndex &&
            widget.accountListViewModel != null &&
            realIndex < widget.accountListViewModel!.accounts.length &&
            widget.accountListViewModel?.selected.label !=
                widget.accountListViewModel?.accounts[realIndex].label) {
          widget.accountListViewModel!.select(widget.accountListViewModel!.accounts[realIndex]);
        }

        children.add(_buildCard(
            visualIndex, realIndex, numCards, parentWidth, order, compactMode, overlapAmount));
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

  Future<void> depositToL2() async {
    PaymentRequest? paymentRequest = null;

    if (widget.dashboardViewModel.type == WalletType.litecoin) {
      final depositAddress = bitcoin!.getUnusedMwebAddress(widget.dashboardViewModel.wallet);
      if ((depositAddress?.isNotEmpty ?? false)) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$depositAddress"));
      }
    } else if (widget.dashboardViewModel.type == WalletType.bitcoin) {
      final depositAddress =
          await bitcoin!.getUnusedSpakDepositAddress(widget.dashboardViewModel.wallet);
      if ((depositAddress?.isNotEmpty ?? false)) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$depositAddress"));
      }
    }

    if (FeatureFlag.hasNewUiExtraPages && widget.dashboardViewModel.type == WalletType.bitcoin) {
      final page = getIt.get<NewSendPage>(
          param1: SendPageParams(
        initialPaymentRequest: paymentRequest,
        unspentCoinType: UnspentCoinType.nonMweb,
        mode: SendPageModes.lightningDeposit,
      ));
      showCupertinoModalBottomSheet(
          context: context,
          barrierColor: Colors.black.withAlpha(128),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ModalNavigator(parentContext: context, rootPage: Material(child: page))),
            );
          });
    } else {
      Navigator.pushNamed(
        context,
        Routes.send,
        arguments: {
          'paymentRequest': paymentRequest,
          'coinTypeToSpendFrom': UnspentCoinType.nonMweb,
        },
      );
    }
  }

  Future<void> withdrawFromL2() async {
    PaymentRequest? paymentRequest = null;
    UnspentCoinType unspentCoinType = UnspentCoinType.any;
    final withdrawAddress = bitcoin!.getUnusedSegwitAddress(widget.dashboardViewModel.wallet);

    if (widget.dashboardViewModel.type == WalletType.litecoin) {
      if ((withdrawAddress?.isNotEmpty ?? false)) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$withdrawAddress"));
      }
      unspentCoinType = UnspentCoinType.mweb;
    } else if (widget.dashboardViewModel.type == WalletType.bitcoin) {
      if ((withdrawAddress?.isNotEmpty ?? false)) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$withdrawAddress"));
      }
      unspentCoinType = UnspentCoinType.lightning;
    }

    if (FeatureFlag.hasNewUiExtraPages && widget.dashboardViewModel.type == WalletType.bitcoin) {
      final page = getIt.get<NewSendPage>(
          param1: SendPageParams(
        initialPaymentRequest: paymentRequest,
        unspentCoinType: unspentCoinType,
        mode: SendPageModes.lightningWithdrawal,
      ));
      showCupertinoModalBottomSheet(
          context: context,
          barrierColor: Colors.black.withAlpha(128),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ModalNavigator(parentContext: context, rootPage: Material(child: page))),
            );
          });
    } else {
      Navigator.pushNamed(
        context,
        Routes.send,
        arguments: {
          'paymentRequest': paymentRequest,
          'coinTypeToSpendFrom': unspentCoinType,
        },
      );
    }
  }
}
