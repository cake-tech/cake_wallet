import "dart:io";

import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_creation/keychain_creation_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_creation/keychain_creation_presentation_event.dart";
import "package:cake_wallet/new-ui/widgets/keychain_creation/keychain_creation_description.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class BackupTypeSelectionPage extends StatefulWidget {
  const BackupTypeSelectionPage({required this.bloc, super.key});

  @override
  State<BackupTypeSelectionPage> createState() => BackupTypeSelectionPageState();

  final KeychainCreationBloc bloc;

  static final keychainLabel = Platform.isAndroid ? "Keystore" : "Keychain";
}

class BackupTypeSelectionPageState extends State<BackupTypeSelectionPage> {
  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: BlocPresentationListener<KeychainCreationBloc, KeychainCreationPresentationEvent>(
          bloc: widget.bloc,
          listener: (context, event) {
            if (event is KeychainSaveFailed) {
              _showKeychainSaveFailed(context, event.error.toString());
            }
          },
          child: BlocConsumer<KeychainCreationBloc, KeychainCreationState>(
            bloc: widget.bloc,
            listener: (context, state) {
              if (state case final KeychainStateComplete s) {
                if (s.redirectToSeed) {
                  Navigator.of(context).pushNamed(Routes.preSeedPage);
                } else {
                  if (widget.bloc.walletType == WalletType.bitcoin) {
                    Navigator.of(context).pushNamed(Routes.lightningUsernamePage, arguments: true);
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is KeychainCreationNotLoaded) {
                return Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      const CupertinoActivityIndicator(),
                      Text(S.of(context).loading_backup_methods),
                    ],
                  ),
                );
              }

              bool useKeychain;
              if (state case final KeychainCreationStateWithUseKeychain s) {
                useKeychain = s.useKeychain;
              } else {
                useKeychain = true;
              }
              return SafeArea(
                child: Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).recovery_method,
                      leadingWidget: const SizedBox(
                        height: 52,
                      ),
                      leadingSemanticLabel: S.of(context).seed_alert_back,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          spacing: 24,
                          children: [
                            const CakeImageWidget(
                              imageUrl: "assets/new-ui/backup_type_selection.svg",
                              width: 140,
                              height: 140,
                            ),
                            Column(
                              spacing: 12,
                              children: [
                                Text(
                                  S.of(context).choose_recovery_method_option,
                                ),
                                GestureDetector(
                                  onTap: () => _showExplainer(context),
                                  child: Row(
                                    spacing: 8,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        S.of(context).what_is_the_difference,
                                        style:
                                            TextStyle(color: Theme.of(context).colorScheme.primary),
                                      ),
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            NewListSections(
                              sections: {
                                "": [
                                  ListItemRegularRow(
                                    keyValue: "keychain",
                                    showArrow: false,
                                    label: BackupTypeSelectionPage.keychainLabel,
                                    onTap: () => widget.bloc
                                        .add(const KeychainModeChanged(useKeychain: true)),
                                    tickable: true,
                                    ticked: useKeychain,
                                    iconPath: "assets/new-ui/settings_row_icons/seed.svg",
                                    subtitle: S.of(context).recommended,
                                  ),
                                  ListItemRegularRow(
                                    keyValue: "seed",
                                    showArrow: false,
                                    label: S.of(context).seed_phrase,
                                    onTap: () => widget.bloc
                                        .add(const KeychainModeChanged(useKeychain: false)),
                                    tickable: true,
                                    ticked: !useKeychain,
                                    iconPath: "assets/new-ui/settings_row_icons/backup.svg",
                                  ),
                                ],
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        spacing: 16,
                        children: [
                          Text(
                            S.of(context).see_seed_phrase_in_settings,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          NewPrimaryButton(
                            onPressed: () => widget.bloc.add(const KeychainModeAccepted()),
                            isLoading: state is KeychainStateSaving,
                            text: S.of(context).continue_text,
                            color: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

  void _showExplainer(BuildContext context) => showMaterialModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => const KeychainCreationDescriptionModal(),
      );

  void _showKeychainSaveFailed(BuildContext context, String error) => showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).failed_to_save_keychain,
          alertContent: error,
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
        ),
      );
}
