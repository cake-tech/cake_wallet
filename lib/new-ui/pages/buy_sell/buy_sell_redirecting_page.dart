import 'package:cake_wallet/buy/sell_buy_states.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/buy/buy_sell_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BuySellRedirectingPage extends StatefulWidget {
  const BuySellRedirectingPage({super.key, required this.buySellViewModel});

  final BuySellViewModel buySellViewModel;

  @override
  State<BuySellRedirectingPage> createState() => _BuySellRedirectingPageState();
}

class _BuySellRedirectingPageState extends State<BuySellRedirectingPage> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2)).then((_) async {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.buySellViewModel.launchTrade(context));
      setState(() {
        _hasRedirected = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
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
        child: Observer(
          builder: (_) {
            final showExitButton =
                _hasRedirected || widget.buySellViewModel.buySellQuotState is BuySellQuotFailed;

            return SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox.shrink(),
                  Observer(
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
                                  S.of(context).could_not_proceed_with_trade,
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
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 24,
                        children: [
                          CakeImageWidget(
                            imageUrl: Theme.of(context).brightness == Brightness.light
                                ? widget.buySellViewModel.selectedQuote!.lightIconPath
                                : widget.buySellViewModel.selectedQuote!.darkIconPath,
                            width: 64,
                            height: 64,
                          ),
                          Column(
                            spacing: 10,
                            children: [
                              Text(
                                "${S.of(context).connecting_you_to} ${widget.buySellViewModel.selectedQuote!.provider.title}...",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                  "${widget.buySellViewModel.fiatAmount} ${widget.buySellViewModel.fiatCurrency} → ${widget.buySellViewModel.amountForQuote(widget.buySellViewModel.selectedQuote!).toStringWithSymbol(fractionalDigits: 8)}")
                            ],
                          )
                        ],
                      );
                    },
                  ),
                  showExitButton
                      ? Padding(
                          padding: EdgeInsets.all(18),
                          child: NewPrimaryButton(
                            onPressed: Navigator.of(context).pop,
                            text: S.of(context).close,
                            color: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : SizedBox.shrink()
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
