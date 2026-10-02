import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:flutter/material.dart";

class NetworkPageScaffold extends StatelessWidget {
  const NetworkPageScaffold({
    required this.title,
    required this.body,
    this.bottom,
    this.onBack,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottom = this.bottom;

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.surface, colors.surfaceDim],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ModalTopBar(
                title: title,
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
                leadingSemanticLabel: S.of(context).seed_alert_back,
                onLeadingPressed: onBack ?? () => Navigator.of(context).maybePop(),
                padding: const EdgeInsets.all(20),
                titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.08,
                    ),
              ),
              Expanded(child: body),
              if (bottom != null) bottom,
            ],
          ),
        ),
      ),
    );
  }
}
