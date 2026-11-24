import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:flutter/material.dart";

void nothing() {}

const double _kButtonSize = 36;
const EdgeInsets _kBarPadding = EdgeInsets.all(18);

const double _kTitleFontSize = 18;
const double _kTitleFontSizeWithBottomText = 16;
const double _kBottomTextFontSize = 12;

const double _kTitleTopOffset = 6;
const double _kTitleTopOffsetWithBottomText = -4;

const double _kTitleButtonGap = 8;

const double _kTitleLeadingSpacing = 12;

const double _kTitleSubtitleSpacing = 4;

const double _kLeftAlignedTitleInset = 12;

const Duration _kSwitchDuration = Duration(milliseconds: 200);

const double _kTrailingTextHorizontalPadding = 16;

const String _kDefaultTestId = "modal_top_bar";

class ModalTopBar extends StatelessWidget {
  ModalTopBar({
    required this.title,
    super.key,
    this.subtitle,
    this.onLeadingPressed = nothing,
    this.onTrailingPressed = nothing,
    this.leadingIcon,
    this.trailingIcon,
    this.trailingText,
    this.padding,
    this.bottomText,
    this.leadingWidget,
    this.trailingWidget,
    this.titleLeadingWidget,
    this.alignTitleLeft = false,
    this.leadingSemanticLabel,
    this.trailingSemanticLabel,
    this.testId,
  }) {
    if (leadingIcon != null && leadingWidget != null) {
      throw ArgumentError("Cannot have both leadingIcon and leadingWidget");
    }
    if (trailingIcon != null && trailingWidget != null) {
      throw ArgumentError("Cannot have both trailingIcon and trailingWidget");
    }
    if (trailingText != null && (trailingIcon != null || trailingWidget != null)) {
      throw ArgumentError("trailingText cannot be combined with trailingIcon or trailingWidget");
    }
  }

  static const buttonSize = _kButtonSize;

  final String title;
  final String? subtitle;
  final String? bottomText;
  final VoidCallback onLeadingPressed;
  final VoidCallback onTrailingPressed;
  final Widget? leadingIcon;
  final EdgeInsets? padding;
  final Widget? trailingIcon;
  final Widget? leadingWidget;
  final Widget? trailingWidget;
  final Widget? titleLeadingWidget;
  final String? trailingText;
  final bool alignTitleLeft;
  final String? leadingSemanticLabel;
  final String? trailingSemanticLabel;
  final String? testId;

  bool get _hasBottomText => bottomText != null && bottomText!.isNotEmpty;

  bool get _hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  String get _baseTestId => testId ?? _kDefaultTestId;

  @override
  Widget build(BuildContext context) {
    final title = _TitleBlock(
      title: this.title,
      bottomText: _hasBottomText ? bottomText : null,
      titleLeadingWidget: titleLeadingWidget,
      alignLeft: alignTitleLeft,
      testId: "${_baseTestId}_title_key",
    );
    final subtitleWidget = _hasSubtitle ? _Subtitle(text: subtitle!) : null;

    final leading = _buildLeading(context);
    final trailing = _buildTrailing();

    return Padding(
      padding: padding ?? _kBarPadding,
      child: alignTitleLeft
          ? _buildLeftAligned(leading, trailing, title, subtitleWidget)
          : _buildCentered(leading, trailing, title, subtitleWidget),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leadingWidget != null) return leadingWidget!;
    if (leadingIcon == null) return const SizedBox(width: _kButtonSize);

    return ModernButton(
      key: ValueKey(leadingIcon.hashCode),
      size: _kButtonSize,
      onPressed: onLeadingPressed,
      icon: leadingIcon!,
      semanticLabel: leadingSemanticLabel,
      testId: "${_baseTestId}_leading_key",
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildTrailing() {
    if (trailingText != null) {
      return _TrailingTextButton(
        text: trailingText!,
        onPressed: onTrailingPressed,
        testId: "${_baseTestId}_trailing_key",
      );
    }
    if (trailingIcon == null && trailingWidget == null) {
      return const SizedBox(width: _kButtonSize);
    }

    return AnimatedSwitcher(
      duration: _kSwitchDuration,
      child: trailingIcon != null
          ? ModernButton(
              key: ValueKey(trailingIcon.hashCode),
              size: _kButtonSize,
              onPressed: onTrailingPressed,
              icon: trailingIcon!,
              semanticLabel: trailingSemanticLabel,
              testId: "${_baseTestId}_trailing_key",
            )
          : trailingWidget!,
    );
  }

  Widget _buildCentered(Widget leading, Widget trailing, Widget title, Widget? subtitle) {
    final hasTitleLeading = titleLeadingWidget != null;
    final inset = hasTitleLeading ? _kButtonSize + _kTitleButtonGap : null;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: _hasBottomText ? _kTitleTopOffsetWithBottomText : _kTitleTopOffset,
          left: inset,
          right: inset,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: _kTitleSubtitleSpacing,
            children: [
              if (hasTitleLeading) Expanded(child: title) else title,
              if (subtitle != null) subtitle,
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [leading, trailing],
        ),
      ],
    );
  }

  Widget _buildLeftAligned(Widget leading, Widget trailing, Widget title, Widget? subtitle) => Row(
        children: [
          leading,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kLeftAlignedTitleInset),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: _kTitleSubtitleSpacing,
                  children: [
                    Flexible(child: title),
                    if (subtitle != null) subtitle,
                  ],
                ),
              ),
            ),
          ),
          trailing,
        ],
      );
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.bottomText,
    required this.titleLeadingWidget,
    required this.alignLeft,
    required this.testId,
  });

  final String title;
  final String? bottomText;
  final Widget? titleLeadingWidget;
  final bool alignLeft;
  final String testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBottomText = bottomText != null;
    final hasTitle = title.isNotEmpty;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontSize: hasBottomText ? _kTitleFontSizeWithBottomText : _kTitleFontSize,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: _kSwitchDuration,
          child: Semantics(
            key: ValueKey(title),
            container: hasTitle,
            identifier: hasTitle ? testId : null,
            header: hasTitle,
            // Android reads the heading from headingLevel since the
            // Flutter 3.41 engine; header: alone only covers iOS.
            headingLevel: hasTitle ? 1 : null,
            child: titleLeadingWidget == null
                ? Text(title, style: titleStyle)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: _kTitleLeadingSpacing,
                    children: [
                      ExcludeSemantics(child: titleLeadingWidget),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasBottomText)
          Text(
            bottomText!,
            style: TextStyle(
              fontSize: _kBottomTextFontSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TrailingTextButton extends StatelessWidget {
  const _TrailingTextButton({
    required this.text,
    required this.onPressed,
    required this.testId,
  });

  final String text;
  final VoidCallback onPressed;
  final String testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      identifier: testId,
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: _kButtonSize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kTrailingTextHorizontalPadding),
              child: Center(
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
