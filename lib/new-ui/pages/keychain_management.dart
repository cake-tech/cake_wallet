import "dart:io";

import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_management/keychain_management_bloc.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/date_formatter.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class KeychainManagementPage extends StatelessWidget {
  const KeychainManagementPage({required this.bloc, super.key});

  final KeychainManagementBloc bloc;

  String get cloudServiceName => Platform.isAndroid ? "Google Keystore" : "iCloud Keychain";

  @override
  Widget build(BuildContext context) =>
      ColoredBox(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        child: BlocBuilder<KeychainManagementBloc, KeychainManagementState>(
          bloc: bloc,
          builder: (context, state) =>
              Column(
                children: [
                  ModalTopBar(
                    title: "",
                    leadingIcon: const Icon(Icons.arrow_back_ios_new),
                    onLeadingPressed: Navigator
                        .of(context)
                        .pop,
                    leadingSemanticLabel: S
                        .of(context)
                        .seed_alert_back,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        spacing: 24,
                        children: [
                          ModalHeader(
                            iconPath: "assets/new-ui/cloud_keys.svg",
                            message: S.of(context).cloud_keys_desc(cloudServiceName),
                            title: S
                                .of(context)
                                .cloud_keys,
                          ),
                          if (state is KeychainManagementNotLoaded) const CupertinoActivityIndicator(),
                          if (state is KeychainManagementLoaded)
                            NewListSections(
                              showHeader: true,
                              sections: {
                                S.of(context).saved_to_cloud(cloudServiceName): state
                                    .keychainWallets
                                    .map(
                                      (item) =>
                                      ListItemToggle(
                                        iconPath:
                                        deserializeFromInt(item.walletTypeRaw).iconPath,
                                        keyValue: item.name,
                                        label: item.name,
                                        subtitle:
                                        "${S
                                            .of(context)
                                            .saved} ${DateFormatter
                                            .withCurrentLocal(hasTime: false)
                                            .format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            item.creationTime,
                                          ),
                                        )}",
                                        value: true,
                                        onChanged: (val) {
                                          bloc.add(
                                              ItemUnsaved(state.keychainWallets.indexOf(item)));
                                        },
                                      ),
                                )
                                    .toList(),
                                S
                                    .of(context)
                                    .not_saved: state.savableWallets
                                    .map(
                                      (item) =>
                                      ListItemToggle(
                                        iconPath: item.type.iconPath,
                                        keyValue: item.name,
                                        label: item.name,
                                        value: false,
                                        onChanged: (val) {
                                          bloc.add(ItemSaved(state.savableWallets.indexOf(item)));
                                        },
                                      ),
                                )
                                    .toList(),
                                if(state.unsupportedKeychainItems.isNotEmpty)
                                  S
                                      .of(context)
                                      .unsupported: state.unsupportedKeychainItems.map((item) =>
                                      ListItemRegularRow(
                                          iconPath: deserializeFromInt(item.walletTypeRaw).iconPath,
                                          keyValue: item.name,
                                          label: item.name,
                                          subtitle: S
                                              .of(context)
                                              .unsupported_keychain_item,
                                          showArrow: false,),).toList(),
                                if(state.unsupportedKeychainItems.isNotEmpty || state.keychainWallets.isNotEmpty)
                              "": [
                                ListItemRegularRow(
                                    keyValue: "delete all",
                                    label: S.of(context).delete_all_keychain_data,
                                    onTap: () => _confirmClear(context), foregroundColor: Theme.of(context).colorScheme.error, showArrow: false)
                              ]
                          },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).delete_all_keychain_data,
        alertContent: S.of(dialogContext).clear_keychain_confirmation,
        leftButtonText: S.of(dialogContext).yes,
        rightButtonText: S.of(dialogContext).no,
        actionLeftButton: () => Navigator.of(dialogContext).pop(true),
        actionRightButton: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (confirmed ?? false) {
      bloc.add(const KeychainCleared());
    }
  }
}
