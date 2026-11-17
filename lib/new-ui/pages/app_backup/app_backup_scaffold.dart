import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class AppBackupScaffold extends StatelessWidget {
  const AppBackupScaffold({
    required this.body,
    this.footer,
    this.title,
    this.showBackButton = true,
    super.key,
  });

  final Widget body;
  final Widget? footer;
  final String? title;
  final bool showBackButton;

  Future<void> _goBack(BuildContext context) async {
    if (!await Navigator.of(context).maybePop() && context.mounted) {
      AppBackupPage.exit(context);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            child: Column(
              children: [
                ModalTopBar(
                  title: title ?? S.of(context).app_backup,
                  leadingIcon: showBackButton ? const Icon(Icons.arrow_back_ios_new) : null,
                  leadingSemanticLabel: S.of(context).seed_alert_back,
                  onLeadingPressed: () => showBackButton ? _goBack(context) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: body,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      );
}

class AppBackupMessage extends StatelessWidget {
  const AppBackupMessage({required this.title, this.description, this.titleStyle, super.key});

  final String title;
  final String? description;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                titleStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: -0.08),
          ),
          if (description != null)
            Text(
              description!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: -0.07,
                  ),
            ),
        ],
      );
}

class BackupPasswordField extends StatelessWidget {
  const BackupPasswordField({
    required this.controller,
    required this.onChanged,
    this.isError = false,
    this.isValid = false,
    this.minLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isError;
  final bool isValid;
  final int minLines;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isError
                ? Theme.of(context).colorScheme.error
                : isValid
                    ? Colors.green
                    : Colors.transparent,
          ),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          textAlign: TextAlign.center,
          minLines: minLines,
          maxLines: 4,
          style: TextStyle(
            fontFamily: "IBM Plex Mono",
            fontSize: 16,
            letterSpacing: -0.08,
            color: isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            isCollapsed: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
        ),
      );
}

class AppBackupHint extends StatelessWidget {
  const AppBackupHint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.customColors.warningContainerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.customColors.warningOutlineColor,
                letterSpacing: -0.07,
              ),
        ),
      );
}
