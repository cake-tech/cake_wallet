import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/clickable_message_text.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

/// Shows a truncated preview of a transaction message. Tapping it opens a
/// scrollable dialog with the full message where any URLs are clickable.
class TransactionMessagePreview extends StatelessWidget {
  const TransactionMessagePreview({super.key, required this.message});

  final String message;

  static const int previewCharLimit = 90;

  bool get _isTruncated => message.characters.length > previewCharLimit;

  String get _preview => _isTruncated
      ? '${message.characters.take(previewCharLimit).toString().trimRight()}…'
      : message;

  void _showFullMessage(BuildContext context) {
    final theme = Theme.of(context);

    showPopUp<void>(
      context: context,
      builder: (dialogContext) => CakePayAlertModal(
        title: S.of(dialogContext).transaction_details_message,
        content: ClickableMessageText(
          text: message,
          textStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          linkStyle: TextStyle(fontSize: 14, color: theme.colorScheme.primary),
        ),
        actionTitle: S.of(dialogContext).got_it,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showFullMessage(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 1.0),
              child: Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
