import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/settings/payjoin_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PayjoinSettingsPage extends StatelessWidget {
  PayjoinSettingsPage(this._payjoinSettingsViewModel);

  final PayjoinSettingsViewModel _payjoinSettingsViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).payjoin,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Observer(builder: (_) {
                return Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      SettingsSwitcherCell(
                        title: S.current.use_payjoin,
                        value: _payjoinSettingsViewModel.usePayjoin,
                        onValueChange: (_, bool value) {
                          _payjoinSettingsViewModel.setUsePayjoin(value);
                        },
                      ),
                      SettingsCellWithArrow(
                        title: S.of(context).payjoin_servers,
                        handler: (BuildContext context) =>
                            Navigator.of(context).pushNamed(Routes.managePayjoinServers),
                      ),
                      SettingsCellWithArrow(
                        title: S.of(context).payjoin_logs,
                        handler: (BuildContext context) =>
                            Navigator.of(context).pushNamed(Routes.payjoinLogs),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
