import "package:flutter/material.dart";

class SeedPageScaffold extends StatelessWidget {
  const SeedPageScaffold({
    required this.content,
    this.footer,
    this.alignTop = false,
    super.key,
  });

  final Widget content;
  final Widget? footer;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Align(
                        alignment: alignTop ? Alignment.topCenter : Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(18, alignTop ? 0 : 16, 18, 16),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
