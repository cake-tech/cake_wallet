import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/send_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/card_design.dart';
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
      required this.onCompactModeBackgroundCardsTapped});

  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;
  final VoidCallback onCompactModeBackgroundCardsTapped;
  final bool lightningMode;

  @override
  _CardsViewState createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.dashboardViewModel.cardOrder.length - 1;
    reaction(
        (_) => widget.dashboardViewModel.cardOrder.keys.toList(),
        (_) => setState(() {
              _selectedIndex = widget.dashboardViewModel.cardOrder.length - 1;
            }));
  }

  static const Duration animDuration = Duration(milliseconds: 200);
  static const int compactModeTreshold = 4;
  static const int maxCards = 5;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.878;

  Widget _buildCard(int visualIndex, int realIndex, int numCards, double parentWidth,
      Map<int, int> order, bool compactMode, double overlapAmount) {
    final baseTop = overlapAmount * (numCards - 1);
    final scaleFactor = compactMode ? 1 : 0.96;

    final howFarBehind = (_selectedIndex - visualIndex + numCards) % numCards;
    final scale = pow(scaleFactor, howFarBehind).toDouble();

    final top = baseTop - (howFarBehind * overlapAmount);

    final left = (parentWidth - cardWidth) / 2.0;

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
        child: GestureDetector(
          onTap: () {
            if (compactMode && visualIndex != 0) {
              widget.onCompactModeBackgroundCardsTapped();
            } else {
              setState(() {
                if (widget.accountListViewModel != null)
                  widget.accountListViewModel!
                      .select(widget.accountListViewModel!.accounts[realIndex]);
                _selectedIndex = visualIndex;
              });
            }
          },
          onLongPress: () {
            if (_selectedIndex == visualIndex) {
              widget.dashboardViewModel.balanceViewModel.switchBalanceValue();
            };
            HapticFeedback.heavyImpact();
          },
          child: Observer(builder: (_) {
            if(realIndex >= (widget.accountListViewModel?.accounts.length ?? 1)) {
              return Container();
            }
            final account = widget.accountListViewModel?.accounts[realIndex];

            // The second balance should always be the lightning balance
            final walletBalanceRecord = widget.dashboardViewModel.balanceViewModel.formattedBalances
                .elementAt(widget.lightningMode ? 1 : 0);

            final walletBalance = walletBalanceRecord.availableBalance;
            final walletFiatBalance = walletBalanceRecord.fiatAvailableBalance;

            // the card designs is empty if widget gets built before it loads.
            // should get populated before user sees anything
            final CardDesign cardDesign;
            if (widget.dashboardViewModel.cardDesigns.isEmpty)
              cardDesign = CardDesign.genericDefault;
            else if(widget.lightningMode)
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
                : [
                    BalanceCardAction(
                      label: S.current.buy,
                      icon: Icons.arrow_forward,
                      onTap: () => Navigator.of(context).pushNamed(Routes.buySellPage),
                    )
                  ];

            return BalanceCard(
              width: cardWidth,
              accountName: accountName,
              accountBalance: accountBalance,
              designSwitchDuration: Duration(milliseconds: 150),
              assetName: walletBalanceRecord.formattedAssetTitle,
              balance: walletBalance,
              fiatBalance: walletFiatBalance,
              selected: _selectedIndex == visualIndex,
              design: cardDesign,
              actions: actions,
            );
          }),
        ),
      ),
    );
  }

  double _getBoxHeight(int numCards, double overlapAmount) {
    return
        /* height of initial card */
        (2 / 3.2) * (cardWidth) +
            /* height of bg card * amount of bg cards */
            overlapAmount * ((numCards) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final parentWidth = MediaQuery.of(context).size.width;
      final children = <Widget>[];

    int numCards = widget.dashboardViewModel.wallet.type == WalletType.bitcoin
        ? 1
        : widget.dashboardViewModel.cardDesigns.length;
        if(numCards == 0) numCards = 1;

      if (_selectedIndex >= (numCards)) {
        _selectedIndex = 0;
      }

      final order = widget.dashboardViewModel.cardOrder.length != numCards
          ? Map<int, int>.fromEntries(
              List.generate(numCards, (i) => MapEntry(i, i)),
            )
          : widget.dashboardViewModel.cardOrder;

      final bool compactMode = numCards >= compactModeTreshold;
      final double overlapAmount = compactMode ? 5.0 : 60.0;

      for (int i = min(numCards - 1, maxCards); i >= 0; i--) {
        int visualIndex = (_selectedIndex - i + numCards) % numCards;

        int realIndex = order[visualIndex]!;

        children.add(_buildCard(
            visualIndex, realIndex, numCards, parentWidth, order, compactMode, overlapAmount));
      }

      return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        height: _getBoxHeight(numCards, overlapAmount),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: SizedBox(
            key: ValueKey(_getBoxHeight(numCards, overlapAmount)),
            width: double.infinity,
            height: _getBoxHeight(numCards, overlapAmount),
            child: Stack(alignment: Alignment.center, children: children),
          ),
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
        mode: SendPageModes.l2deposit,
      ));
      showCupertinoModalBottomSheet(context: context, barrierColor: Colors.black.withAlpha(128), builder: (context){
        return FractionallySizedBox(
            heightFactor: 0.65,
            child:ModalNavigator(parentContext:context,rootPage: Material(child: page))
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
        mode: SendPageModes.l2withdrawal,
      ));
      showCupertinoModalBottomSheet(context: context, barrierColor: Colors.black.withAlpha(128), builder: (context){
        return FractionallySizedBox(
          heightFactor: 0.65,
          child:ModalNavigator(parentContext:context,rootPage: Material(child: page))
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
