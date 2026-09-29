import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_provider_preferences.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PegarouteProvidersSettings extends StatelessWidget {
  const PegarouteProvidersSettings({
    super.key,
    required this.preferences,
    required this.decentralizedOnly,
  });

  final PegarouteProviderPreferences preferences;
  final bool Function() decentralizedOnly;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ModalTopBar(
            title: 'Pegaroute ${S.of(context).providers}',
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).maybePop,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Observer(builder: (_) {
                return Column(
                  spacing: 24,
                  children: [
                    Text('${S.of(context).automatic} — ${S.of(context).best_rate}'),
                    NewListSections(sections: {
                      '': [
                        for (final provider in PegarouteProviderPreferences.providers.entries)
                          ListItemToggle(
                            keyValue: provider.key,
                            label: provider.value,
                            value: preferences.isEnabled(provider.key),
                            onChanged: (value) => preferences.setEnabled(provider.key, value),
                            leadingEndWidget: Text(
                              S.of(context).decentralized,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    }),
                  ],
                );
              }),
            ),
          ),
        ],
      );
}
