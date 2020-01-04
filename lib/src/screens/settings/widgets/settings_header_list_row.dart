import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/palette.dart';
import 'package:provider/provider.dart';

class SettingsHeaderListRow extends StatelessWidget {
  final String title;

  SettingsHeaderListRow({this.title});

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 28.0,
        ),
        Container(
          padding: EdgeInsets.only(left: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Observer(
                  builder: (_) => Text(
                    settingsStore.itemHeaders[title],
                    style: TextStyle(
                        fontSize: 15.0, color: Palette.wildDarkBlue),
                  ))
            ],
          ),
        ),
        SizedBox(
          height: 14.0,
        ),
      ],
    );
  }

}