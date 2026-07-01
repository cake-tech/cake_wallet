import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:flutter/material.dart';

class BuySellProviderPage extends StatelessWidget {
  const BuySellProviderPage({super.key, required this.buySellViewModel});

  final BuySellViewModel buySellViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceDim,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
          child: Column(
        children: [
          ModalTopBar(
            title: _pageTitle,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(child: Column(

          ))
        ],
      )),
    );
  }

  String get _pageTitle => buySellViewModel.mode == BuySellPageMode.buy
      ? S.current.buy
      : S.current.sell + " " + (buySellViewModel.cryptoCurrency.fullName ?? "");
}
