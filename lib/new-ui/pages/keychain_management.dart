import "dart:io";

import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_management/keychain_management_bloc.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
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
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: BlocBuilder<KeychainManagementBloc, KeychainManagementState>(
          bloc: bloc,
          builder: (context, state) => Column(
            children: [
              ModalTopBar(
                title: "",
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
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
                        iconPath: "assets/new-ui/cloud_keys.svg",
                        message: S.of(context).cloud_keys_desc(cloudServiceName),
                        title: S.of(context).cloud_keys,
                      ),
                      if (state is KeychainManagementNotLoaded) const CupertinoActivityIndicator(),
                      if (state is KeychainManagementLoaded)
                        NewListSections(sections: {
                          if (state.unsupportedKeychainItems.isNotEmpty || state.items.isNotEmpty)
                            "": [
                              ListItemRegularRow(
                                  keyValue: "delete all",
                                  label: S.of(context).delete_all_keychain_data,
                                  onTap: () => _confirmClear(context),
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  showArrow: false)
                            ],
                          if (state.unsupportedKeychainItems.isNotEmpty)
                            S.of(context).unsupported: state.unsupportedKeychainItems
                                .map(
                                  (item) => ListItemRegularRow(
                                    iconPath: deserializeFromInt(item.walletTypeRaw).iconPath,
                                    keyValue: item.name,
                                    label: item.name,
                                    subtitle: S.of(context).unsupported_keychain_item,
                                    showArrow: false,
                                  ),
                                )
                                .toList(),
                        }),
                      if (state is KeychainManagementLoaded)
                        Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).contact_list_wallets,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if(state.hasUnrestoredWallets)
                                Row(spacing:4, children: [
                                  Text(S.of(context).some_wallets_unrestored, style: TextStyle(fontSize: 12, color: context.currentTheme.customColors.warningOutlineColor),),
                                  Icon(size:14,Icons.info_outline, color: context.currentTheme.customColors.warningOutlineColor,)
                                ],),
                              NewListSections(sections: {
                                "": state.items
                                    .map(
                                      (item) => ListItemRegularRow(
                                        iconPath: item.type.iconPath,
                                        keyValue: item.name,
                                        label: item.name,
                                        subtitle: item.dateSaved == null
                                            ? S.of(context).not_saved
                                            : "${S.of(context).saved} ${DateFormatter.withCurrentLocal(hasTime: false).format(item.dateSaved!)}",
                                        trailingWidget: Row(spacing:8,
                                          children: [
if(!item.isRestored)CakeImageWidget(imageUrl: "assets/new-ui/not_restored.svg",width:24,height:24,colorFilter: ColorFilter.mode(context.currentTheme.customColors.warningOutlineColor,BlendMode.srcIn),),
                                            StandardSwitch(value: item.isBackedUp,
                                            onTapped: () {
                                              bloc.add(item.isBackedUp
                                                  ? ItemUnsaved(state.items.indexOf(item))
                                                  : ItemSaved(state.items.indexOf(item)));
                                            },),
                                          ],
                                        )
                                      ),
                                    )
                                    .toList(),
                              })
                            ]),
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
