import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class WCSessionAuthRequestWidget extends StatelessWidget {
  const WCSessionAuthRequestWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SingleChildScrollView(child: child),
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            PrimaryButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(WCBottomSheetResult.reject);
                }
              },
              text: S.current.cancel,
              color: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(WCBottomSheetResult.one);
                }
              },
              text: S.current.sign_one,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(WCBottomSheetResult.all);
                }
              },
              text: S.current.sign_all,
              color: Theme.of(context).colorScheme.secondaryContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ],
    );
  }
}
