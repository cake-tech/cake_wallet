import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SwapProviderInitialPreferenceModal extends StatelessWidget {
  const SwapProviderInitialPreferenceModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(),
            ModalTopBar(title: S.of(context).exchange_providers),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                spacing: 12,
                children: [
                  SvgPicture.asset("assets/new-ui/exchange_providers.svg"),
                  Text(
                    "${S.of(context).swap_provider_initial_desc} Cake Wallet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                  ),
                  Column(
                    spacing: 12,
                    children: [
                      NewPrimaryButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          text: S.of(context).decentralized_only,
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          textColor: Theme.of(context).colorScheme.primary),
                      NewPrimaryButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          text: S.of(context).best_rate_mixed,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary)
                    ],
                  ),
                  SizedBox(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
