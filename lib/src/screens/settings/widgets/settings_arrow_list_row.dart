import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

class SettingsArrowListRow extends StatelessWidget {
  SettingsArrowListRow({@required this.onTaped, this.title});

  final VoidCallback onTaped;
  final String title;

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);
    final _cakeArrowImage = Image.asset('assets/images/select_arrow.png',
        color: Theme.of(context).primaryTextTheme.caption.color);

    return Container(
      color: Theme.of(context).accentTextTheme.title.backgroundColor,
      child: ListTile(
          contentPadding: EdgeInsets.only(left: 24.0, right: 24.0),
          title: Observer(
              builder: (_) => Text(
                    settingsStore.itemHeaders[title],
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).primaryTextTheme.title.color),
                  )),
          trailing: _cakeArrowImage,
          onTap: onTaped),
    );
  }
}
