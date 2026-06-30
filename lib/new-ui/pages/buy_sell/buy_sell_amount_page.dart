import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:flutter/material.dart';

class NewBuySellAmountPage extends StatelessWidget {
  const NewBuySellAmountPage({super.key, required this.mode, required this.buySellViewModel});

  final BuySellPageMode mode;
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
        child: Column(children: [
          ModalTopBar(title: _pageTitle, leadingIcon: Icon(Icons.close), onLeadingPressed: Navigator.of(context).pop,),
          Expanded(child: GridView.builder(itemCount: 6, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 150), itemBuilder: (context, index){


          }))
        ],),
      ),
    );
  }

  String get _pageTitle =>
      mode == BuySellPageMode.buy ? S.current.buy : S.current.sell +
          ((buySellViewModel.cryptoCurrencies.length == 1)
              ? " ${buySellViewModel.cryptoCurrencies.first.fullName}"
              : "");
}


