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
            ModalTopBar(title: "Exchange Providers"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                spacing: 12,
                children: [
                  SvgPicture.asset("assets/new-ui/exchange_providers.svg"),
                  Text(
                    "Select the type of swap provider you prefer to use when swapping in Cake Wallet.",
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
                          text: "Decentralized Only",
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          textColor: Theme.of(context).colorScheme.primary),
                      NewPrimaryButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          text: "Best Rate (Mixed)",
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
