import 'package:flutter/material.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_store.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/picker.dart';

class PresentProviderPicker extends StatelessWidget {
  PresentProviderPicker({@required this.exchangeStore});

  final ExchangeStore exchangeStore;

  @override
  Widget build(BuildContext context) {
    final Image arrowBottom =
    Image.asset('assets/images/arrow_bottom_purple_icon.png',
        color: Theme.of(context).primaryTextTheme.title.color,
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
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).primaryTextTheme.title.color)),
                Observer(
                    builder: (_) => Text('${exchangeStore.provider.title}',
                        style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).primaryTextTheme.caption.color)))
              ],
            ),
            SizedBox(width: 5),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: arrowBottom,
            )
          ],
        )
    );
  }

  void _presentProviderPicker(BuildContext context) {
    final items = exchangeStore.providersForCurrentPair();
    final selectedItem = items.indexOf(exchangeStore.provider);
    final images = List<Image>();

    for (ExchangeProvider provider in items) {
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
      }
    }

    showDialog<void>(
        builder: (_) => Picker(
            items: items,
            images: images,
            selectedAtIndex: selectedItem,
            title: S.of(context).change_exchange_provider,
            onItemSelected: (ExchangeProvider provider) =>
                exchangeStore.changeProvider(provider: provider)),
        context: context);
  }
}