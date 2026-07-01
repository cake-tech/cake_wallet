import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class CakePayAlertModal extends StatelessWidget {
  const CakePayAlertModal({
    super.key,
    required this.title,
    required this.content,
    required this.actionTitle,
    this.showCloseButton = true,
    this.dismissible = false,
  });

  final String title;
  final Widget content;
  final String actionTitle;
  final bool showCloseButton;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return AlertBackground(
      dismissible: dismissible,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(title,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  Flexible(child: SingleChildScrollView(child: content)),
                  const SizedBox(height: 24),
                  PrimaryButton(
                      onPressed: () => Navigator.pop(context),
                      text: actionTitle,
                      color: theme.colorScheme.surfaceContainer,
                      textColor: theme.colorScheme.primary),
                  if (showCloseButton) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainer,
                        child: Icon(Icons.close, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
