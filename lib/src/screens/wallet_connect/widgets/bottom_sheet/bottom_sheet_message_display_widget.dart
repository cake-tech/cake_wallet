import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class BottomSheetMessageDisplayWidget extends StatelessWidget {
  final String message;
  final bool isError;

  const BottomSheetMessageDisplayWidget({super.key, required this.message, this.isError = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isError ? S.current.error : S.current.successful,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              color: Theme.of(context).appBarTheme.titleTextStyle!.color!,
              padding: const EdgeInsets.all(0.0),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.close_sharp),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
