import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseTextFormField extends StatelessWidget {
  BaseTextFormField({
    this.onChanged,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.textAlign = TextAlign.start,
    this.autovalidateMode,
    this.hintText = '',
    this.maxLines = 1,
    this.inputFormatters,
    this.textColor,
    this.hintColor,
    this.fillColor,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.enableInteractiveSelection = true,
    this.obscureText = false,
    this.validator,
    this.textStyle,
    this.placeholderTextStyle,
    this.maxLength,
    this.focusNode,
    this.initialValue,
    this.onSubmit,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.contentPadding,
    this.alignLabelWithHint = false,
    this.floatingLabelBehavior,
    this.cursorColor,
    this.cursorWidth,
    this.isDense,
    this.enableIMEPersonalizedLearning,
    this.onFieldSubmitted,
    this.hasUnderlineBorder = false,
    this.borderWidth = 1.0,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    super.key,
    this.suffixText,
  });

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final AutovalidateMode? autovalidateMode;
  final String? hintText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Color? textColor;
  final Color? hintColor;
  final Color? fillColor;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final bool? enabled;
  final FormFieldValidator<String>? validator;
  final TextStyle? placeholderTextStyle;
  final TextStyle? textStyle;
  final int? maxLength;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool? enableInteractiveSelection;
  final String? initialValue;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final void Function(String)? onSubmit;
  final bool obscureText;
  final bool? autofocus;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final void Function(String)? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final bool? alignLabelWithHint;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Color? cursorColor;
  final double? cursorWidth;
  final bool? isDense;
  final bool? enableIMEPersonalizedLearning;
  final void Function(String)? onFieldSubmitted;
  final bool hasUnderlineBorder;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning ?? true,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth ?? 2.0,
      onChanged: onChanged,
      autofocus: autofocus ?? false,
      autocorrect: autocorrect ?? true,
      enableSuggestions: enableSuggestions ?? true,
      enableInteractiveSelection: enableInteractiveSelection,
      readOnly: readOnly,
      initialValue: initialValue,
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: textAlign,
      autovalidateMode: autovalidateMode,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      maxLength: maxLength,
      onFieldSubmitted: onSubmit,
      style: textStyle ??
          Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16.0, color: textColor ?? Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        isDense: isDense,
        alignLabelWithHint: alignLabelWithHint,
        contentPadding: contentPadding,
        floatingLabelBehavior: floatingLabelBehavior ?? FloatingLabelBehavior.never,
        prefixIconConstraints:
            prefixIconConstraints ?? const BoxConstraints(minWidth: 40, minHeight: 0),
        prefix: prefix,
        prefixIcon: prefixIcon,
        suffixIconConstraints:
            suffixIconConstraints ?? const BoxConstraints(minWidth: 0, minHeight: 0),
        suffix: suffix,
        suffixIcon: suffixIcon,
        filled: !hasUnderlineBorder,
        fillColor:
            hasUnderlineBorder ? null : fillColor ?? Theme.of(context).colorScheme.surfaceContainer,
        hintStyle: placeholderTextStyle ??
            Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: hintColor ?? Theme.of(context).hintColor, fontSize: 16),
        hintText: hasUnderlineBorder ? hintText : null,
        labelText: !hasUnderlineBorder ? hintText : null,
        labelStyle: !hasUnderlineBorder ? placeholderTextStyle : null,
        border: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  style: borderWidth == 0.0 ? BorderStyle.none : BorderStyle.solid,
                  width: borderWidth,
                ),
              )
            : null,
        focusedBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  style: borderWidth == 0.0 ? BorderStyle.none : BorderStyle.solid,
                  width: borderWidth,
                ),
              )
            : null,
        disabledBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              )
            : null,
        enabledBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  style: borderWidth == 0.0 ? BorderStyle.none : BorderStyle.solid,
                  width: borderWidth,
                ),
              )
            : null,
        errorBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              )
            : null,
      ),
      validator: validator,
    );
  }
}
