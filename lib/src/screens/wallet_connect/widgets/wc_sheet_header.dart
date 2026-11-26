import "package:cake_wallet/generated/i18n.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:flutter/material.dart';

class WCSheetHeader extends StatelessWidget {
  const WCSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkResponse(
              radius: 36,
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(WCBottomSheetResult.reject);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsetsDirectional.fromSTEB(0, 4, 8, 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  button: true,
                  label: S.of(context).reject,
                  child: Icon(Icons.close, size: 20, color: colors.onSurface),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(letterSpacing: -0.09),
          ),
        ],
      ),
    );
  }
}
