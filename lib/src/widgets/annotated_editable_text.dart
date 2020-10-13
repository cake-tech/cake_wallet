import 'package:flutter/material.dart';

class Annotation extends Comparable<Annotation> {
  Annotation({@required this.range, this.style});

  final TextRange range;
  final TextStyle style;

  @override
  int compareTo(Annotation other) => range.start.compareTo(other.range.start);
}

class TextAnnotation extends Comparable<TextAnnotation> {
  TextAnnotation({@required this.text, this.style});

  final TextStyle style;
  final String text;

  @override
  int compareTo(TextAnnotation other) => text.compareTo(other.text);
}

class AnnotatedEditableText extends EditableText {
  AnnotatedEditableText({
    Key key,
    FocusNode focusNode,
    TextEditingController controller,
    TextStyle style,
    ValueChanged<String> onChanged,
    ValueChanged<String> onSubmitted,
    Color cursorColor,
    Color selectionColor,
    Color backgroundCursorColor,
    TextSelectionControls selectionControls,
    @required this.words,
  })  : textAnnotations = words
      .map((word) => TextAnnotation(
      text: word,
      style: TextStyle(
          color: Colors.black,
          backgroundColor: Colors.transparent,
          fontWeight: FontWeight.normal,
          fontSize: 20)))
      .toList(),
        super(
        maxLines: null,
        key: key,
        focusNode: focusNode,
        controller: controller,
        cursorColor: cursorColor,
        style: style,
        keyboardType: TextInputType.text,
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
        showCursor: true,
      ) {
    textAnnotations.add(TextAnnotation(
        text: ' ', style: TextStyle(backgroundColor: Colors.transparent)));
  }

  final List<String> words;
  final List<TextAnnotation> textAnnotations;

  @override
  AnnotatedEditableTextState createState() => AnnotatedEditableTextState();
}

class AnnotatedEditableTextState extends EditableTextState {
  @override
  AnnotatedEditableText get widget => super.widget as AnnotatedEditableText;

  List<Annotation> getRanges() {
    final source = widget.textAnnotations
        .map((item) => range(item.text, textEditingValue.text)
        .map((range) => Annotation(style: item.style, range: range)))
        .expand((e) => e)
        .toList();
    final result = List<Annotation>();
    final text = textEditingValue.text;
    source.sort();
    Annotation prev;

    for (var item in source) {
      if (prev == null) {
        if (item.range.start > 0) {
          result.add(Annotation(
              range: TextRange(start: 0, end: item.range.start),
              style: TextStyle(
                  color: Colors.black, backgroundColor: Colors.transparent)));
        }
        result.add(item);
        prev = item;
        continue;
      } else {
        if (prev.range.end > item.range.start) {
          // throw StateError('Invalid (intersecting) ranges for annotated field');
        } else if (prev.range.end < item.range.start) {
          result.add(Annotation(
              range: TextRange(start: prev.range.end, end: item.range.start),
              style: TextStyle(
                  color: Colors.red, backgroundColor: Colors.transparent)));
        }

        result.add(item);
        prev = item;
      }
    }

    if (result.length > 0 && result.last.range.end < text.length) {
      result.add(Annotation(
          range: TextRange(start: result.last.range.end, end: text.length),
          style: TextStyle( backgroundColor: Colors.transparent)));
    }
    return result;
  }

  List<TextRange> range(String pattern, String source) {
    final result = List<TextRange>();

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
    final ranges = getRanges();

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