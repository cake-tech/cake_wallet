import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/sell_buy_states.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_dropdown.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/buy_sell/buy_sell_confirmation_page.dart';
import 'package:cake_wallet/new-ui/pages/buy_sell/buy_sell_payment_method_page.dart';
import 'package:cake_wallet/new-ui/widgets/buy_sell/buy_sell_selector_modal.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BuySellProviderPage extends StatefulWidget {
  const BuySellProviderPage({super.key, required this.buySellViewModel});

  final BuySellViewModel buySellViewModel;

  @override
  State<BuySellProviderPage> createState() => _BuySellProviderPageState();
}

class _BuySellProviderPageState extends State<BuySellProviderPage> {
  bool _allProvidersExpanded = false;

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
              if (widget.buySellViewModel.buySellQuotState is BuySellQuotFailed) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 24,
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 48),
                    Column(
                      spacing: 10,
                      children: [
                        Text(
                          S.of(context).could_not_load_quotes,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        Text((widget.buySellViewModel.buySellQuotState as BuySellQuotFailed)
                                .errorMessage ??
                            S.of(context).please_try_again_later)
                      ],
                    )
                  ],
                );
              }

              if (widget.buySellViewModel.buySellQuotState is BuySellQuotLoading) {
                return Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      CupertinoActivityIndicator(),
                      Text(
                        S.of(context).loading_rates,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: NewListSections(showHeader: true, sections: {
                  "": [
                    ListItemRegularRow(
                        keyValue: "payment method",
                        label: S.of(context).payment_method,
                        showArrow: true,
                        onTap: () {
                          final page =
                              BuySellPaymentMethodPage(buySellViewModel: widget.buySellViewModel);
                          Navigator.of(context).push(CupertinoPageRoute(
                              builder: (context) => Material(
                                    color: Colors.transparent,
                                    child: page,
                                  )));
                        },
                        trailingText: widget.buySellViewModel.selectedPaymentMethod?.title)
                  ],
                  S.of(context).available_providers: [
                    ...widget.buySellViewModel.sortedRecommendedQuotes.map(quoteListItem),
                    if(widget.buySellViewModel.sortedQuotes.isNotEmpty)
                    ListItemDropdown(
                        keyValue: "more options",
                        label: S.of(context).more_options,
                        onTap: () {
                          setState(() {
                            _allProvidersExpanded = !_allProvidersExpanded;
                          });
                        }),
                    if (_allProvidersExpanded)
                      ...widget.buySellViewModel.sortedQuotes.map(quoteListItem)
                  ]
                }),
              );
            },
          ))
        ],
      )),
    );
  }

  String get _pageTitle =>
      (widget.buySellViewModel.mode == BuySellPageMode.buy ? S.current.buy : S.current.sell) +
      " " +
      (widget.buySellViewModel.cryptoCurrency.fullName ?? "");

  ListItem quoteListItem(Quote quote) => ListItemRegularRow(
      keyValue: quote.provider.title,
      label: quote.rampName ?? quote.provider.title,
      secondaryLabel: quote.rampName != null ? quote.provider.title : null,
      subtitle: quote.badges.isEmpty ? null : quote.badges.join(" - "),
      subtitleColor: Theme.of(context).colorScheme.primary,
      iconPath: quote.darkIconPath,
      onTap: () {
        widget.buySellViewModel.changeOption(quote);
        navigateToConfirmation(context);
      },
      leadingIconSize: 32,
      trailingWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          Text(widget.buySellViewModel
              .amountForQuote(quote)
              .toStringWithSymbol(fractionalDigits: 8)),
          Text(
              "= ${widget.buySellViewModel.fiatAmountForQuote(quote).toStringWithSymbol(fractionalDigits: 2, trimZeros: false)}",
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))
        ],
      ));

  void navigateToConfirmation(BuildContext context) {
    final page = BuySellConfirmationPage(buySellViewModel: widget.buySellViewModel);
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => Material(
              color: Colors.transparent,
              child: page,
            )));
  }
}
