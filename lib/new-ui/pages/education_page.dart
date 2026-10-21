import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

abstract class EducationPage extends StatefulWidget {
  const EducationPage({required this.settingsStore, super.key});

  final SettingsStore settingsStore;

  String get educationId;
  String get title;
  String get iconPath;
  String get completionLabel;
  List<EducationSlide> get slides;
  String progressLabel(int current, int total);

  bool get isDismissed => settingsStore.isEducationDismissed(educationId);

  Future<void> show(BuildContext context) async {
    await showCupertinoModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => this,
    );
    await settingsStore.dismissEducation(educationId);
  }

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _complete() {
    if (_isCompleting) {
      return;
    }

    _isCompleting = true;
    Navigator.of(context).pop();
  }

  Future<void> _continue(int pageCount) async {
    if (_currentPage == pageCount - 1) {
      _complete();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.slides;

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CakeImageWidget(
                      imageUrl: widget.iconPath,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
                    const Spacer(),
                    ModernButton(
                      size: 36,
                      icon: const Icon(Icons.close),
                      semanticLabel: S.of(context).close,
                      onPressed: _complete,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: pages,
                ),
              ),
              Semantics(
                label: widget.progressLabel(_currentPage + 1, pages.length),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        key: ValueKey("education-dot-$index"),
                        duration: const Duration(milliseconds: 200),
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: NewPrimaryButton(
                  onPressed: () => _continue(pages.length),
                  text: _currentPage == pages.length - 1
                      ? widget.completionLabel
                      : S.of(context).continue_text,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class EducationSlide extends StatelessWidget {
  const EducationSlide({
    required this.children,
    super.key,
    this.distributeChildren = false,
  });

  final List<Widget> children;
  final bool distributeChildren;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: distributeChildren
                ? IntrinsicHeight(
                    child: Column(
                      children: [
                        for (var index = 0; index < children.length; index++) ...[
                          children[index],
                          if (index < children.length - 1) ...[
                            const SizedBox(height: 24),
                            const Spacer(),
                          ],
                        ],
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children,
                  ),
          ),
        ),
      );
}

class EducationText extends StatelessWidget {
  const EducationText({
    required this.text,
    super.key,
    this.highlightedText,
    this.secondary = false,
    this.warning = false,
  });

  final String text;
  final String? highlightedText;
  final bool secondary;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: warning
          ? context.customColors.warningOutlineColor
          : secondary
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onSurface,
    );
    final highlight = highlightedText;
    final highlightStart = highlight == null ? -1 : text.indexOf(highlight);

    if (highlight == null || highlightStart < 0) {
      return Text(text, textAlign: TextAlign.center, style: style);
    }

    final highlightEnd = highlightStart + highlight.length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, highlightStart)),
          TextSpan(
            text: text.substring(highlightStart, highlightEnd),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: text.substring(highlightEnd)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
