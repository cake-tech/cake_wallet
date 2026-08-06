import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_restore/keychain_restore_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_restore/keychain_restore_presentation_event.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class KeychainRestorePageParams {
  KeychainRestorePageParams({required this.isInitial});

  final bool isInitial;
}

class KeychainRestorePage extends StatelessWidget {
  const KeychainRestorePage({required this.bloc, required this.isInitial, super.key});

  final bool isInitial;
  final KeychainRestoreBloc bloc;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: BlocPresentationListener<KeychainRestoreBloc, KeychainRestorePresentationEvent>(
            bloc: bloc,
            listener: (context, event) {
              if (event is WalletOpened) {
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
              }
            },
            child: BlocConsumer<KeychainRestoreBloc, KeychainRestoreState>(
              bloc: bloc,
              listener: (context, state) {
                if (isInitial &&
                    (state is KeychainRestoreNoWallets || state is KeychainRestoreUnavailable)) {
                  navigateToWelcome(context);
                }
              },
              builder: (context, state) {
                if (state is KeychainRestoreNotLoaded) {
                  return Center(
                    child: Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CupertinoActivityIndicator(),
                        Text(S.of(context).looking_for_wallets),
                      ],
                    ),
                  );
                }
          
                return Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).restore_existing,
                      leadingWidget: isInitial
                          ? const SizedBox(
                              height: 52,
                            )
                          : null,
                      leadingIcon: isInitial ? null : const Icon(Icons.arrow_back_ios_new),
                      onLeadingPressed: isInitial ? () {} : Navigator.of(context).pop,
                      leadingSemanticLabel: isInitial ? null : S.of(context).seed_alert_back,
                    ),
                    Expanded(
                      child: Column(
                        spacing: 24,
                        children: [
                          const CakeImageWidget(
                            imageUrl: "assets/new-ui/key_hero.svg",
                            width: 175,
                            height: 175,
                          ),
                          Text(
                            getDescriptionText(state.runtimeType),
                            textAlign: TextAlign.center,
                          ),
                          if (state is KeychainRestoreStateWithWallets)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: SingleChildScrollView(
                                  child: NewListSections(
                                    sections: {
                                      "": state.walletsAvailable
                                          .map((item) {
                                            final walletType = deserializeFromInt(item.walletTypeRaw);
                                            final iconPath =
                                                walletTypeToCryptoCurrency(walletType).iconPath;

                                            if (state is KeychainRestoreStateWithWalletProgress &&
                                                !state.walletsSelected.contains(item)) {
                                              return null;
                                            }

                                            if (state is KeychainRestoreComplete &&
                                                !state.walletsRestored.contains(item)) {
                                              return null;
                                            }

                                            return ListItemRegularRow(
                                              keyValue: item.name,
                                              iconPath: iconPath,
                                              label: item.name,
                                              showArrow: state is KeychainRestoreComplete,
                                              trailingWidget:
                                                  trailingWidgetForItem(context, item, state),
                                              onTap: () => bloc.add(
                                                state is KeychainRestoreComplete
                                                    ? WalletOpenSelected(
                                                        state.walletsAvailable.indexOf(item))
                                                    : WalletToggled(
                                                        state.walletsAvailable.indexOf(item)),
                                              ),
                                            );
                                          })
                                          .whereType<ListItemRegularRow>()
                                          .toList(),
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        spacing: 12,
                        children: [
                          if (isInitial && state is KeychainRestoreSelection)
                            NewPrimaryButton(
                              onPressed: () => navigateToWelcome(context),
                              text: S.of(context).skip,
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              textColor: Theme.of(context).colorScheme.primary,
                            ),
                          if (state is KeychainRestoreSelection)
                            NewPrimaryButton(
                              onPressed: () => bloc.add(const RestoreInitiated()),
                              text: S.of(context).continue_text,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          if (!isInitial && state is KeychainRestoreNoWallets)
                            NewPrimaryButton(
                              onPressed: Navigator.of(context).pop,
                              text: S.of(context).close,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

  Widget trailingWidgetForItem(
    BuildContext context,
    KeychainData item,
    KeychainRestoreState state,
  ) {
    if (state is KeychainRestoreSelection && state.walletsSelected.contains(item)) {
      return Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary);
    }

    if (state is KeychainRestoreComplete) {
      return const SizedBox.shrink();
    }

    if (state is KeychainRestoreStateWithWalletProgress) {
      if (state.walletsFailed.contains(item)) {
        return Text(
          S.of(context).error,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        );
      } else if (state.walletsRestored.contains(item)) {
        return Text(
          S.of(context).restored,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        );
      }
      return const CupertinoActivityIndicator();
    }

    return const SizedBox.shrink();
  }

  String getDescriptionText(Type stateType) => switch (stateType) {
        KeychainRestoreSelection =>
          isInitial ? S.current.restore_existing_desc : S.current.restore_existing_desc_non_initial,
        KeychainRestoring => "${S.current.restoring_your_wallets}...",
        KeychainRestoreComplete => S.current.restore_complete_select_wallet,
        KeychainRestoreNoWallets => S.current.no_wallets_found_to_restore,
        _ => ""
      };

  void navigateToWelcome(BuildContext context) =>
      Navigator.of(context).popAndPushNamed(Routes.welcomePage);
}
