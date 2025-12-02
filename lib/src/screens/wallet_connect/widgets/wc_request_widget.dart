import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_verify_context_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCRequestWidget extends StatelessWidget {
  WCRequestWidget({
    required this.child,
    this.verifyContext,
    this.onAccept,
    this.onReject,
  });

  final Widget child;
  final VerifyContext? verifyContext;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WCVerifyContextWidget(
          verifyContext: verifyContext,
        ),
        const SizedBox(height: 8),
        Flexible(
          child: SingleChildScrollView(child: child),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: PrimaryButton(
                onPressed: onReject ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(WCBottomSheetResult.reject);
                      }
                    },
                text: S.current.reject,
                color: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.onError,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                onPressed: onAccept ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(WCBottomSheetResult.one);
                      }
                    },
                text: S.current.approve,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
