import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/check_box_picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresentProviderPicker extends StatelessWidget {
  PresentProviderPicker({@required this.exchangeViewModel, @required this.sharedPreferences});

  final ExchangeViewModel exchangeViewModel;
  final SharedPreferences sharedPreferences;

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
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white)),
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

  void _presentProviderPicker(BuildContext context) async {
    final Map<String, dynamic> exchangeProvidersSelection = json
        .decode(sharedPreferences.getString(PreferencesKey.exchangeProvidersSelection) ?? "{}") as Map<String, dynamic>;

    await showPopUp<void>(
        builder: (BuildContext popUpContext) => CheckBoxPicker(
            items: exchangeViewModel.providerList
                .map((e) => CheckBoxItem(
                      e.title,
                      (exchangeProvidersSelection[e.title] as bool) ?? e.isEnabled,
                    ))
                .toList(),
            title: S.of(context).change_exchange_provider,
            onChanged: (int index, bool value) {
              if (!exchangeViewModel.providerList[index].isAvailable) {
                showPopUp<void>(
                    builder: (BuildContext popUpContext) => AlertWithOneAction(
                        alertTitle: 'Error',
                        alertContent: 'The exchange is blocked in your region.',
                        buttonText: S.of(context).ok,
                        buttonAction: () => Navigator.of(context).pop()),
                    context: context);
                return;
              }
              exchangeProvidersSelection[exchangeViewModel.providerList[index].title] = value;
            }),
        context: context);

    await sharedPreferences.setString(
      PreferencesKey.exchangeProvidersSelection,
      json.encode(exchangeProvidersSelection),
    );
  }
}
