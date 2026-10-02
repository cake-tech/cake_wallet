import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

abstract class ExplainerPage extends StatelessWidget {
  const ExplainerPage({super.key});

  String get viewedPreferencesKey;

  String title(BuildContext context);

  String headline(BuildContext context);

  String? subtitle(BuildContext context) => null;

  String description(BuildContext context);

  Widget illustration(BuildContext context);

  Widget? attribution(BuildContext context) => null;

  Future<void> show(BuildContext context) => showMaterialModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => this,
      );

  Future<void> showIfNeeded(BuildContext context, SettingsStore settingsStore) async {
    if (!context.mounted || settingsStore.hasViewedExplainer(viewedPreferencesKey)) return;

    await show(context);
    await settingsStore.setExplainerViewed(viewedPreferencesKey);
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              spacing: 48,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        headingLevel: 1,
                        child: Text(
                          title(context),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    ModernButton(
                      size: 36,
                      icon: const Icon(Icons.close),
                      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      semanticLabel: S.of(context).close,
                      onPressed: Navigator.of(context).pop,
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 24,
                          children: [
                            illustration(context),
                            Column(
                              spacing: 12,
                              children: [
                                Text(
                                  headline(context),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                if (subtitle(context) != null)
                                  Text(
                                    subtitle(context)!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                            if (attribution(context) != null) attribution(context)!,
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                description(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                NewPrimaryButton(
                  onPressed: Navigator.of(context).pop,
                  text: S.of(context).continue_text,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      );
}
