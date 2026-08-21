import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/buy_sell/buy_sell_redirecting_page.dart';
import 'package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BuySellConfirmationPage extends StatelessWidget {
  const BuySellConfirmationPage({super.key, required this.buySellViewModel});

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
            Expanded(child: Observer(
              builder: (_) {
                return Column(
                  spacing: 24,
                  children: [
                    Column(
                      spacing: 4,
                      children: [
                        Text(
                          "${buySellViewModel.fiatAmount} ${buySellViewModel.fiatCurrency}",
                          style: TextStyle(fontSize: 32),
                        ),
                        Text(
                          "≈ ${buySellViewModel.amountForQuote(buySellViewModel.selectedQuote!).toStringWithSymbol(fractionalDigits: 8)}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: NewListSections(sections: {
                        "": [
                          ListItemRegularRow(
                              keyValue: "provider",
                              label: S.of(context).provider,
                              trailingWidget: Row(
                                spacing: 8,
                                children: [
                                  CakeImageWidget(
                                    imageUrl: Theme.of(context).brightness == Brightness.light
                                        ? buySellViewModel.selectedQuote!.lightIconPath
                                        : buySellViewModel.selectedQuote!.darkIconPath,
                                    width: 24,
                                    height: 24,
                                  ),
                                  Text(
                                    buySellViewModel.selectedQuote!.rampName ??
                                        buySellViewModel.selectedQuote!.provider.title,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox.shrink()
                                ],
                              )),
                          ListItemRegularRow(
                              showArrow: false,
                              keyValue: "payment method",
                              label: S.of(context).payment_method,
                              trailingText: buySellViewModel.selectedQuote!.paymentType.title),
                          ListItemRegularRow(
                              showArrow: false,
                              keyValue: "rate",
                              label: S.of(context).rate,
                              trailingText: buySellViewModel.selectedQuote!.topLeftSubTitle)
                        ]
                      }),
                    )
                  ],
                );
              },
            )),
            Padding(
              padding: EdgeInsets.all(18),
              child: NewPrimaryButton(
                  onPressed: () => confirm(context),
                  text: S.of(context).proceed,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary),
            )
          ],
        ),
      ),
    );
  }

  String get _pageTitle =>
      (buySellViewModel.mode == BuySellPageMode.buy ? S.current.buy : S.current.sell) +
      " " +
      (buySellViewModel.cryptoCurrency.fullName ?? "");

  void confirm(BuildContext context) {
    final page = BuySellRedirectingPage(buySellViewModel: buySellViewModel);
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
        builder: (context) => Material(
              child: page,
            )));
  }
}
