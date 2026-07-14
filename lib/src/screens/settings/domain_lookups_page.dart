import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/settings/connection_sync_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DomainLookupsPage extends BasePage {
  DomainLookupsPage(this._connectionsSyncViewModel);

  @override
  String get title => S.current.domain_looks_up;

  final ConnectionSyncViewModel _connectionsSyncViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            children: _connectionsSyncViewModel.domainLookupSources
                .map(
                  (source) => SettingsSwitcherCell(
                    title: source.label,
                    leading: source.iconPath.isNotEmpty
                        ? CakeImageWidget(
                            imageUrl: source.iconPath,
                            width: 24,
                            height: 24,
                          )
                        : SizedBox(width: 24, height: 24),
                    value: _connectionsSyncViewModel.lookupValue(source),
                    onValueChange: (_, bool value) =>
                        _connectionsSyncViewModel.setLookupValue(source, value),
                  ),
                )
                .toList(),
          ),
        );
      }),
    );
  }
}
