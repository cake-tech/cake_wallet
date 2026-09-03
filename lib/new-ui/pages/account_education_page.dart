import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:shared_preferences/shared_preferences.dart";

class AccountEducationPage extends StatefulWidget {
  const AccountEducationPage({required this.preferences, super.key});

  final SharedPreferences preferences;

  static bool shouldShow(SharedPreferences preferences) =>
      !(preferences.getBool(PreferencesKey.accountsEducationSeen) ?? false);

  static Future<void> markSeen(SharedPreferences preferences) async {
    await preferences.setBool(PreferencesKey.accountsEducationSeen, true);
  }

  static Future<void> show(BuildContext context, SharedPreferences preferences) async {
    await showCupertinoModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountEducationPage(preferences: preferences),
    );
    await markSeen(preferences);
  }

  @override
  State<AccountEducationPage> createState() => _AccountEducationPageState();
}

class _AccountEducationPageState extends State<AccountEducationPage> {
  static const _pageCount = 4;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isCompleting) {
      return;
    }

    _isCompleting = true;
    await AccountEducationPage.markSeen(widget.preferences);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _continue() async {
    if (_currentPage == _pageCount - 1) {
      await _complete();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final pages = <Widget>[
      _EducationSlide(
        distributeChildren: true,
        children: [
          _EducationText(text: strings.accounts_education_organize_title),
          Image.asset(
            "assets/new-ui/account_education/accounts_overview.png",
            key: const ValueKey("accounts-education-overview-image"),
            width: 133,
            height: 324,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          _EducationText(
            text: strings.accounts_education_organize_description,
            secondary: true,
          ),
        ],
      ),
      _EducationSlide(
        children: [
          Image.asset(
            "assets/new-ui/account_education/recovery_shield.png",
            key: const ValueKey("accounts-education-recovery-image"),
            width: 213,
            height: 213,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 25.5),
          _EducationText(
            text: strings.accounts_education_recovery_title,
            highlightedText: strings.accounts_education_recovery_highlight,
          ),
          const SizedBox(height: 25.5),
          _EducationText(
            text: strings.accounts_education_recovery_description,
            secondary: true,
          ),
        ],
      ),
      _EducationSlide(
        children: [
          Image.asset(
            "assets/new-ui/account_education/account_order.png",
            key: const ValueKey("accounts-education-order-image"),
            width: 309,
            height: 48,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 51),
          _EducationText(text: strings.accounts_education_order_title),
          const SizedBox(height: 51),
          Image.asset(
            "assets/new-ui/account_education/ordered_account.png",
            key: const ValueKey("accounts-education-ordered-account-image"),
            width: 160,
            height: 99,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 51),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EducationText(
                text: strings.accounts_education_order_description,
                highlightedText: strings.accounts_education_order_highlight,
              ),
              const SizedBox(height: 25.5),
              _EducationText(
                text: strings.accounts_education_order_restore_description,
                secondary: true,
              ),
            ],
          ),
        ],
      ),
      _EducationSlide(
        children: [
          Image.asset(
            "assets/new-ui/account_education/archive_warning.png",
            key: const ValueKey("accounts-education-archive-image"),
            width: 232,
            height: 101,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 51),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EducationText(
                text: strings.accounts_education_archive_title,
                warning: true,
              ),
              const SizedBox(height: 13),
              _EducationText(
                text: strings.accounts_education_archive_description,
                secondary: true,
              ),
            ],
          ),
        ],
      ),
    ];

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
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(strings.accounts, style: Theme.of(context).textTheme.headlineMedium),
                    const Spacer(),
                    ModernButton(
                      size: 36,
                      icon: const Icon(Icons.close),
                      semanticLabel: strings.close,
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
                label: strings.accounts_education_progress(
                  "${_currentPage + 1}",
                  "$_pageCount",
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (index) => AnimatedContainer(
                        key: ValueKey("account-education-dot-$index"),
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
                  onPressed: _continue,
                  text: _currentPage == _pageCount - 1
                      ? strings.accounts_education_understand_continue
                      : strings.continue_text,
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

class _EducationSlide extends StatelessWidget {
  const _EducationSlide({
    required this.children,
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

class _EducationText extends StatelessWidget {
  const _EducationText({
    required this.text,
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
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: warning
          ? context.customColors.warningOutlineColor
          : secondary
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
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
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          TextSpan(text: text.substring(highlightEnd)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
