import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'balance_card.dart';

class CardsView extends StatefulWidget {
  const CardsView(
      {super.key,
      required this.dashboardViewModel,
      required this.accountListViewModel,
      required this.lightningMode});

  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;
  final bool lightningMode;

  @override
  _CardsViewState createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  int? _selectedIndex = 0;

  static const Duration animDuration = Duration(milliseconds: 200);
  static const double overlapAmount = 60.0;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.85;
  late final int numCards;

  @override
  void initState() {
    super.initState();
    numCards = widget.accountListViewModel?.accounts.length ?? 1;
  }

  Widget _buildCard(int index, double parentWidth) {
    final numCards = widget.accountListViewModel?.accounts.length ?? 1;
    final baseTop = overlapAmount * (numCards - 1);
    final scaleFactor = 0.96;

    final howFarBehind = (_selectedIndex! - index + numCards) % numCards;
    final scale = pow(scaleFactor, howFarBehind).toDouble();

    final top = baseTop - (howFarBehind * overlapAmount);

    final left = (parentWidth - cardWidth) / 2.0;

    return AnimatedPositioned(
      key: ValueKey('box_$index'),
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
            setState(() {
              if (widget.accountListViewModel != null)
                widget.accountListViewModel!.select(widget.accountListViewModel!.accounts[index]);
              _selectedIndex = index;
            });
          },
          child: Observer(builder: (_) {
            final account = widget.accountListViewModel?.accounts[index];

            final walletBalanceRecord =
                widget.dashboardViewModel.balanceViewModel.formattedBalances.elementAt(0);
            final walletCurrency =
                widget.lightningMode ? walletBalanceRecord.secondAsset : walletBalanceRecord.asset;
            final walletBalance = widget.lightningMode
                ? walletBalanceRecord.secondAvailableBalance
                : walletBalanceRecord.availableBalance;
            final walletFiatBalance = widget.lightningMode
                ? walletBalanceRecord.fiatSecondAvailableBalance
                : walletBalanceRecord.fiatAvailableBalance;

            // the card designs is empty if widget gets built before it loads.
            // should get populated before user sees anything
            final CardDesign cardDesign;
            if (widget.dashboardViewModel.cardDesigns.isEmpty)
              cardDesign = CardDesign.genericDefault;
            else
              cardDesign = widget.dashboardViewModel.cardDesigns[index];

            final String accountName;
            final String accountBalance;
            if (account == null) {
              accountName = walletCurrency.fullName ?? walletCurrency.title;
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
              assetName: walletCurrency.title,
              balance: walletBalance,
              fiatBalance: walletFiatBalance,
              selected: _selectedIndex == index,
              design: cardDesign,
              actions: actions,
            );
          }),
        ),
      ),
    );
  }

  double _getBoxHeight() {
    return
        /* height of initial card */
        (2 / 3) * (cardWidth) +
            /* height of bg card * amount of bg cards */
            overlapAmount * ((widget.accountListViewModel?.accounts.length ?? 1) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final children = <Widget>[];

        if (_selectedIndex! >= (widget.accountListViewModel?.accounts.length ?? 1)) {
          _selectedIndex = 0;
        }

        for (int i = _selectedIndex!;
            i < (widget.accountListViewModel?.accounts.length ?? 1) + _selectedIndex!;
            i++) {
          if (i != _selectedIndex) {
            children.add(
                _buildCard(i % (widget.accountListViewModel?.accounts.length ?? 1), parentWidth));
          }
        }

        if (_selectedIndex != null) {
          children.add(_buildCard(_selectedIndex!, parentWidth));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: double.infinity,
            height: _getBoxHeight(),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: SizedBox(
                key: ValueKey(_getBoxHeight()),
                width: double.infinity,
                height: _getBoxHeight(),
                child: Stack(alignment: Alignment.center, children: children),
              ),
            ),
          ),
        );
      },
    );
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

    Navigator.pushNamed(
      context,
      Routes.send,
      arguments: {
        'paymentRequest': paymentRequest,
        'coinTypeToSpendFrom': UnspentCoinType.nonMweb,
      },
    );
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
