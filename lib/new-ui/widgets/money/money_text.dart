import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// The [MoneyText] widget displays [Money] as a formated string of text with single style.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.isHiddenAmount,
    this.useBaseUnit,
    this.fractionalDigits = 8,
    this.showSymbol = true,
    this.withSymbolPrefix = false,
    this.trimZeros = true,
  });

  /// The [MoneyText.optional] returns a widget displaying [Money] as a
  /// formated string or an [SizedBox.shrink].
  static Widget optional(
    Money? amount, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    String? semanticsIdentifier,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
    bool? isHiddenAmount,
    bool? useBaseUnit,
    int fractionalDigits = 8,
    bool showSymbol = true,
    bool withSymbolPrefix = false,
    bool trimZeros = true,
  }) =>
      amount != null
          ? MoneyText(
              amount,
              key: key,
              style: style,
              strutStyle: strutStyle,
              textAlign: textAlign,
              textDirection: textDirection,
              locale: locale,
              softWrap: softWrap,
              overflow: overflow,
              textScaler: textScaler,
              maxLines: maxLines,
              semanticsLabel: semanticsLabel,
              semanticsIdentifier: semanticsIdentifier,
              textWidthBasis: textWidthBasis,
              textHeightBehavior: textHeightBehavior,
              selectionColor: selectionColor,
              isHiddenAmount: isHiddenAmount,
              useBaseUnit: useBaseUnit,
              fractionalDigits: fractionalDigits,
              showSymbol: showSymbol,
              withSymbolPrefix: withSymbolPrefix,
              trimZeros: trimZeros,
            )
          : const SizedBox.shrink();

  /// The amount to display.
  final Money amount;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  ///
  /// The user or platform may override this [style]'s [TextStyle.fontWeight],
  /// [TextStyle.height], [TextStyle.letterSpacing], and [TextStyle.wordSpacing]
  /// via a [MediaQuery] ancestor's [MediaQueryData.boldText],
  /// [MediaQueryData.lineHeightScaleFactorOverride],
  /// [MediaQueryData.letterSpacingOverride], and [MediaQueryData.wordSpacingOverride]
  /// regardless of its [TextStyle.inherit] value.
  final TextStyle? style;

  /// The user or platform may override this [strutStyle]'s [StrutStyle.height]
  /// via a [MediaQuery] ancestor's [MediaQueryData.lineHeightScaleFactorOverride].
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  ///
  /// If this is null [TextStyle.overflow] will be used, otherwise the value
  /// from the nearest [DefaultTextStyle] ancestor will be used.
  final TextOverflow? overflow;

  final TextScaler? textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels applied
  /// directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// const Text(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  final String? semanticsLabel;

  /// A unique identifier for the semantics node for this widget.
  ///
  /// This is useful for cases where the text widget needs to have a uniquely
  /// identifiable ID that is recognized through the automation tools without
  /// having a dependency on the actual content of the text that can possibly be
  /// dynamic in nature.
  final String? semanticsIdentifier;

  final TextWidthBasis? textWidthBasis;

  final TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if [SelectionContainer.maybeOf] returns null
  /// in the [BuildContext] of the [Text] widget.
  ///
  /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
  /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
  /// (semi-transparent grey).
  final Color? selectionColor;

  /// Show the amount in the base unit format of [Money.currency]
  ///
  /// If null, the displayAmountsInSatoshi setting is used.
  final bool? useBaseUnit;

  /// A limit for the display of the fractional digits of the amount
  final int fractionalDigits;

  /// Hide the amount
  ///
  /// If null, the value from the balanceDisplayMode setting is used.
  final bool? isHiddenAmount;

  /// Show the currency symbol
  final bool showSymbol;

  /// Prefix the amount with the currency symbol if [showSymbol] is true
  final bool withSymbolPrefix;

  /// Trim the zeros at the end of an amount
  final bool trimZeros;

  @override
  Widget build(BuildContext context) => BlocBuilder<MoneySettingsCubit, MoneySettingsState>(
        builder: (context, state) => Text(
          isHiddenAmount ?? state.isHidden
              ? "●●●●●●"
              : showSymbol
                  ? amount.toLocalStringWithSymbol(
                      fractionalDigits: fractionalDigits,
                      trimZeros: trimZeros,
                      useBaseUnit: useBaseUnit ?? state.useBaseUnit(amount.currency),
                      withSymbolPrefix: withSymbolPrefix,
                      locale: (locale ?? Localizations.localeOf(context)).toString(),
                    )
                  : amount.toLocalStringWithPrecision(
                      fractionalDigits: fractionalDigits,
                      trimZeros: trimZeros,
                      useBaseUnit: useBaseUnit ?? state.useBaseUnit(amount.currency),
                      locale: (locale ?? Localizations.localeOf(context)).toString(),
                    ),
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: isHiddenAmount ?? state.isHidden
              ? (semanticsLabel ?? S.of(context).amount_hidden)
              : semanticsLabel,
          semanticsIdentifier: semanticsIdentifier,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        ),
      );
}
