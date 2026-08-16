import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_state.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import "package:cake_wallet/src/widgets/image_widgets/confetti_burst_widget.dart";
import "package:cake_wallet/src/widgets/image_widgets/overlapping_icon_stack_rows_widget.dart";
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletCreationSuccessPage extends BasePage {
  WalletCreationSuccessPage();

  @override
  Widget leading(BuildContext context) => const SizedBox.shrink();

  @override
  Widget body(BuildContext context) => const WalletCreationSuccessPageBody();
}

class WalletCreationSuccessPageBody extends StatelessWidget {
  const WalletCreationSuccessPageBody({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<OmniChainWalletBloc, WalletCreationState>(
        listenWhen: (_, current) =>
            (current is WalletCreationOpeningNetwork && !current.canCreate) ||
            current is WalletCreationSeedBackup,
        listener: (context, state) {
          if (state is WalletCreationSeedBackup) {
            Navigator.of(context).pushNamed(Routes.preSeedPage);
            return;
          }
          Navigator.of(context).pushNamed(
            Routes.walletCreationOpeningPage,
            arguments: context.read<OmniChainWalletBloc>(),
          );
        },
        builder: (context, state) {
          final isCreating = state is WalletCreationCreating;

          final (walletName, selectedTypes) = switch (state) {
            WalletCreationSummary(:final groupName, :final selectedTypes) ||
            WalletCreationOpeningNetwork(:final groupName, :final selectedTypes) ||
            WalletCreationSeedBackup(:final groupName, :final selectedTypes) =>
              (
                groupName,
                selectedTypes.toList(),
              ),
            WalletCreationCreating(:final request) => (
                request.groupName,
                request.selectedTypes.toList(),
              ),
            _ => ('', <WalletType>[]),
          };

          final displayName = walletName.isEmpty ? 'My Wallet' : walletName;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const SizedBox(
                  height: 240,
                  child: ConfettiBurst(),
                ),
                Text(
                  "Wallet Created!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '🛍️',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: OverlappingIconStackRows(
                    iconPaths: selectedTypes.map(getCryptoCurrencyIconForWalletListItem).toList(),
                  ),
                ),
                const Spacer(flex: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: PrimaryButton(
                    key: const ValueKey('new_wallet_summary_continue_button_key'),
                    onPressed: () {
                      final bloc = context.read<OmniChainWalletBloc>();
                      final current = bloc.state;

                      if (current is WalletCreationOpeningNetwork && current.canCreate) {
                        bloc.add(OmniChainWalletGroupCreateRequested());
                      } else {
                        bloc.add(OmniChainWalletSummaryConfirmed());
                      }
                    },
                    borderRadius: BorderRadius.circular(999999),
                    text: isCreating ? 'Creating...' : 'Open Wallet',
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    isDisabled: isCreating,
                  ),
                ),
              ],
            ),
          );
        },
      );
}
