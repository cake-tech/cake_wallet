import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

class SettingsTextListRow extends StatelessWidget {
  final VoidCallback onTaped;
  final String title;
  final Widget widget;

  SettingsTextListRow({@required this.onTaped, this.title, this.widget});

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return Container(
      color: Theme.of(context).accentTextTheme.headline.backgroundColor,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 20.0, right: 20.0),
        title: Observer(
            builder: (_) => Text(
                  settingsStore.itemHeaders[title],
                  style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).primaryTextTheme.title.color),
                )),
        trailing: widget,
        onTap: onTaped,
      ),
    );
  }
}
