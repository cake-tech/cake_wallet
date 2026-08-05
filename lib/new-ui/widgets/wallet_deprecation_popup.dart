import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/animated_dropdown.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class WalletDeprecationPopup extends StatelessWidget {
  const WalletDeprecationPopup({super.key, required this.type, this.seed});

  final WalletType type;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    final curr = walletTypeToCryptoCurrency(type);

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalTopBar(
              title: "",
              leadingIcon: Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                spacing: 24,
                children: [
                  CakeImageWidget(
                    imageUrl: curr.iconPath,
                    width: 64,
                    height: 64,
                  ),
                  Text(
                    "${curr.fullName} is no longer supported",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Apologies for the inconvenience.",
                    textAlign: TextAlign.center,
                  ),
                  if (seed != null) ...[
                    Text(
                      "If you need to migrate your seed, you can see it below.",
                      textAlign: TextAlign.center,
                    ),
                    AnimatedDropdown(content: Text(seed!), dropdownText: "Tap to show seed"),
                  ],
                  NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: "Close",
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary),
                  SizedBox()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
