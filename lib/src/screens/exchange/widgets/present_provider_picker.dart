import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';

class PresentProviderPicker extends StatelessWidget {
  PresentProviderPicker({@required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  @override
  Widget build(BuildContext context) {
    final arrowBottom = Image.asset(
        'assets/images/arrow_bottom_purple_icon.png',
        color: Colors.white,
        height: 6);

    return FlatButton(
        onPressed: () => _presentProviderPicker(context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(S.of(context).exchange,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Observer(
                    builder: (_) => Text('${exchangeViewModel.provider.title}',
                        style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.headline.color)))
              ],
            ),
            SizedBox(width: 5),
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: arrowBottom,
            )
          ],
        ));
  }

  void _presentProviderPicker(BuildContext context) {
    final items = exchangeViewModel.providersForCurrentPair();
    final selectedItem = items.indexOf(exchangeViewModel.provider);
    final images = <Image>[];
    String description;

    for (var provider in items) {
      switch (provider.description) {
        case ExchangeProviderDescription.xmrto:
          images.add(Image.asset('assets/images/xmr_btc.png'));
          break;
        case ExchangeProviderDescription.changeNow:
          images.add(Image.asset('assets/images/change_now.png'));
          break;
        case ExchangeProviderDescription.morphToken:
          images.add(Image.asset('assets/images/morph_icon.png'));
          break;
        case ExchangeProviderDescription.sideshift:
          images.add(Image.asset('assets/images/sideshift_icon.png'));
          break;
      }
    }

    showPopUp<void>(
        builder: (BuildContext popUpContext) => Picker(
            items: items,
            images: images,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            description: description,
            onItemSelected: (ExchangeProvider provider) {
              if (!provider.isAvailable) {
                showPopUp<void>(
                    builder: (BuildContext popUpContext) => AlertWithOneAction(
                        alertTitle: 'Error',
                        alertContent: 'The exchange is blocked in your region.',
                        buttonText: S.of(context).ok,
                        buttonAction: () => Navigator.of(context).pop()),
                    context: context);
                return;
              }
              exchangeViewModel.changeProvider(provider: provider);
            }),
        context: context);
  }
}
