import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";

class DefiIntroView extends StatelessWidget {
  const DefiIntroView({
    required this.wordmark,
    required this.description,
    required this.details,
    required this.terms,
    required this.onContinue,
    this.attribution,
    super.key,
  });

  final Widget wordmark;
  final String description;
  final List<ListItem> details;
  final Widget terms;
  final VoidCallback onContinue;
  final Widget? attribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefiScaffold(
      child: Column(
        children: [
          ModalTopBar(
            title: "",
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        wordmark,
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 27),
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        NewListSections(sections: {"details": details}),
                        if (attribution != null) ...[
                          const SizedBox(height: 24),
                          attribution!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              spacing: 16,
              children: [
                terms,
                NewPrimaryButton(
                  onPressed: onContinue,
                  text: S.of(context).continue_text,
                  color: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
