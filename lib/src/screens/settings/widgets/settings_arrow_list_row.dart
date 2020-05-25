import 'package:cake_wallet/palette.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

class SettingsArrowListRow extends StatelessWidget {
  SettingsArrowListRow({@required this.onTaped, this.title});

  final VoidCallback onTaped;
  final String title;
  final _cakeArrowImage = Image.asset('assets/images/select_arrow.png',
      color: PaletteDark.walletCardText);

  @override
  Widget build(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return Container(
      color: PaletteDark.menuList,
      child: ListTile(
          contentPadding: EdgeInsets.only(left: 24.0, right: 24.0),
          title: Observer(
              builder: (_) => Text(
                    settingsStore.itemHeaders[title],
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white),
                  )),
          trailing: _cakeArrowImage,
          onTap: onTaped),
    );
  }
}
