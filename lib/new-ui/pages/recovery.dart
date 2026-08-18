import "dart:io";

import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:flutter/material.dart";

class RecoveryPage extends StatefulWidget {
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  String get cloudServiceName => Platform.isAndroid ? "Google Keystore" : "iCloud Keychain";

  bool _keychainAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkKeychainAvailable();
  }

  Future<void> _checkKeychainAvailable() async {
    final available = await getIt.get<CwKeychain>().available();
    setState(() {
      _keychainAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            ModalTopBar(
              title: "",
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              onLeadingPressed: Navigator.of(context).pop,
              leadingSemanticLabel: S.of(context).seed_alert_back,
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                spacing: 24,
                children: [
                  ModalHeader(
                    iconPath: "assets/new-ui/settings_row_icons/seed.svg",
                    title: S.of(context).recovery_and_keys,
                    message: S.of(context).recovery_and_keys_desc,
                  ),
                  NewListSections(showHeader: true, sections: {
                    S.of(context).wallet_recovery_phrase: [
                      ListItemRegularRow(
                          keyValue: "manual",
                          label: S.of(context).manual_backup,
                          subtitle: S.of(context).manual_backup_desc,
                          iconPath: "assets/new-ui/manual_backup.svg",
                          onTap: () =>
                              Navigator.of(context).pushNamed(Routes.seed, arguments: true)),
                      if (_keychainAvailable)
                        ListItemRegularRow(
                            keyValue: "cloud",
                            label: S.of(context).cloud_keys,
                            subtitle: S.of(context).cloud_keys_desc(cloudServiceName),
                            iconPath: "assets/new-ui/cloud_keys.svg",
                            onTap: () =>
                                Navigator.of(context).pushNamed(Routes.keychainManagementPage)),
                    ],
                    "": [
                      ListItemRegularRow(
                          keyValue: "full app backup",
                          label: S.of(context).full_app_backup,
                          subtitle: S.of(context).full_app_backup_desc,
                          iconPath: "assets/new-ui/full_app_backup.svg",
                          onTap: () => Navigator.of(context).pushNamed(Routes.backup))
                    ]
                  })
                ],
              ),
            ))
          ],
        ),
      );
}
