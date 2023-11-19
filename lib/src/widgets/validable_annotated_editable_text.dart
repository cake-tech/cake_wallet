import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class Annotation extends Comparable<Annotation> {
  Annotation({required this.range, required this.style});

  final TextRange range;
  final TextStyle style;

  @override
  int compareTo(Annotation other) => range.start.compareTo(other.range.start);
}

class TextAnnotation extends Comparable<TextAnnotation> {
  TextAnnotation({required this.text, required this.style});

  final TextStyle style;
  final String text;

  @override
  int compareTo(TextAnnotation other) => text.compareTo(other.text);
}

class ValidatableAnnotatedEditableText extends EditableText {
  ValidatableAnnotatedEditableText({
    Key? key,
    required FocusNode focusNode,
    required TextEditingController controller,
    // required List<String> wordList,
    required Color cursorColor,
    required Color backgroundCursorColor,
    required this.validStyle,
    required this.invalidStyle,
    required this.words,
    TextStyle textStyle = const TextStyle(
        color: Colors.black,
        backgroundColor: Colors.transparent,
        fontWeight: FontWeight.normal,
        fontSize: 16),
    TextSelectionControls? selectionControls,
    Color? selectionColor,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) : super(
            maxLines: null,
            key: key,
            focusNode: focusNode,
            controller: controller,
            cursorColor: cursorColor,
            style: validStyle,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            autofocus: false,
            selectionColor: selectionColor,
            selectionControls: selectionControls,
            backgroundCursorColor: backgroundCursorColor,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            toolbarOptions: const ToolbarOptions(
              copy: true,
              cut: true,
              paste: true,
              selectAll: true,
            ),
            enableSuggestions: false,
            enableInteractiveSelection: true,
            showSelectionHandles: true,
            showCursor: true);

  final List<String> words;
  final TextStyle validStyle;
  final TextStyle invalidStyle;

  @override
  ValidatableAnnotatedEditableTextState createState() =>
      ValidatableAnnotatedEditableTextState();
}

class ValidatableAnnotatedEditableTextState extends EditableTextState {
  @override
  ValidatableAnnotatedEditableText get widget =>
      super.widget as ValidatableAnnotatedEditableText;

  List<Annotation> getRanges() {
    final result = <Annotation>[];
    final text = textEditingValue.text;
    final source = text
        .split(' ')
        .map((word) {
          final ranges = range(word, text);
          final isValid = validate(word);

          return ranges.map((range) => Annotation(
              style: isValid ? widget.validStyle : widget.invalidStyle,
              range: range));
        })
        .expand((e) => e)
        .toList();
    source.sort();
    Annotation? prev;

    for (var item in source) {
      Annotation? annotation;

      if (prev == null) {
        annotation = Annotation(
            range: TextRange(start: 0, end: item.range.start),
            style: TextStyle(
                color: Colors.black, backgroundColor: Colors.transparent));
      } else if (prev.range.end < item.range.start) {
        annotation = Annotation(
            range: TextRange(start: prev.range.end, end: item.range.start),
            style: TextStyle(
                color: Colors.red, backgroundColor: Colors.transparent));
      }

      if (annotation != null) {
        result.add(annotation);
        result.add(item);
        prev = item;
      }
    }

    if (result.length > 0 && result.last.range.end < text.length) {
      result.add(Annotation(
          range: TextRange(start: result.last.range.end, end: text.length),
          style: TextStyle(backgroundColor: Colors.transparent)));
    }

    return result;
  }

  bool validate(String source) => widget.words.indexOf(source) >= 0;

  List<TextRange> range(String pattern, String source) {
    final result = <TextRange>[];

    if (pattern.isEmpty || source.isEmpty) {
      return result;
    }

    for (int index = source.indexOf(pattern);
        index >= 0;
        index = source.indexOf(pattern, index + 1)) {
      final start = index;
      final end = start + pattern.length;
      result.add(TextRange(start: start, end: end));
    }

    return result;
  }

  @override
  TextSpan buildTextSpan() {
    final text = textEditingValue.text;
    final ranges = getRanges().toSet();

    if (ranges.isNotEmpty) {
      return TextSpan(
          style: widget.style,
          children: ranges
              .map((item) => TextSpan(
                  style: item.style, text: item.range.textInside(text)))
              .toList());
    }

    return TextSpan(style: widget.style, text: text);
  }
}
