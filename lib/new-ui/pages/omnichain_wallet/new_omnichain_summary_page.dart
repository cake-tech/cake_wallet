import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewOmnichainSummaryPage extends BasePage {
  NewOmnichainSummaryPage();

  @override
  Widget leading(BuildContext context) => const SizedBox.shrink();

  @override
  Widget body(BuildContext context) => const NewOmnichainSummaryPageBody();
}

class NewOmnichainSummaryPageBody extends StatelessWidget {
  const NewOmnichainSummaryPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmniChainWalletBloc, OmniChainWalletState>(
      builder: (context, state) {
        final walletName = state.groupName.isEmpty ? 'My Wallet' : state.groupName;
        final selectedTypes = state.selectedTypes.toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 60,
                      top: 8,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(251, 80, 3, 0.6),
                        angle: -0.45,
                      ),
                    ),
                    Positioned(
                      right: 48,
                      top: 6,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(0, 153, 255, 0.6),
                        angle: 0.35,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 62,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(255, 221, 0, 0.6),
                        angle: 0.3,
                      ),
                    ),
                    Positioned(
                      right: 112,
                      top: 76,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(255, 221, 0, 0.6),
                        angle: -0.4,
                      ),
                    ),
                    Positioned(
                      left: 92,
                      bottom: 18,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(0, 153, 255, 0.6),
                        angle: 0.2,
                      ),
                    ),
                    Positioned(
                      right: 42,
                      bottom: 12,
                      child: _ConfettiPiece(
                        color: Color.fromRGBO(251, 80, 3, 0.6),
                        angle: -0.35,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Wallet Created!',
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
                walletName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 28),
              Center(
                child: _SelectedWalletTypesPreview(types: selectedTypes),
              ),
              const Spacer(flex: 5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: PrimaryButton(
                  key: const ValueKey('new_wallet_summary_open_wallet_button_key'),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  borderRadius: BorderRadius.circular(999999),
                  text: 'Open Wallet',
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectedWalletTypesPreview extends StatelessWidget {
  const _SelectedWalletTypesPreview({required this.types});

  final List<WalletType> types;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <List<WalletType>>[];
    for (var i = 0; i < types.length; i += 9) {
      rows.add(types.sublist(
        i,
        i + 9 > types.length ? types.length : i + 9,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map(
            (rowTypes) => Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999999),
                color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(120),
              ),
              child: SizedBox(
                width: _rowWidth(rowTypes.length),
                height: 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ...rowTypes.asMap().entries.map(
                          (entry) => Positioned(
                            left: entry.key * 22.0,
                            child: _WalletTypeIcon(type: entry.value),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  double _rowWidth(int count) {
    if (count <= 0) return 0;
    return 30 + ((count - 1) * 22.0);
  }
}

class _WalletTypeIcon extends StatelessWidget {
  const _WalletTypeIcon({required this.type});

  final WalletType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: CakeImageWidget(
          imageUrl: getCryptoCurrencyIconForWalletListItem(type),
          width: 30,
          height: 30,
        ),
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  const _ConfettiPiece({
    required this.color,
    required this.angle,
  });

  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 5,
        height: 18,
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}
