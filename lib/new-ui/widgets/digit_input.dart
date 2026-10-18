import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

class DigitInputController {
  String _text = "";

  String get text => _text;

  set text(String newText) {
    _text = newText;
    for (final listener in _listeners) {
      listener.call();
    }
  }

  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);
}

class DigitInputPill extends StatelessWidget {
  const DigitInputPill({required this.highlighted, super.key, this.digit});

  final String? digit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        width: 51,
        height: 84,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: highlighted
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(digit ?? " ", style: const TextStyle(fontSize: 40)),
          ),
        ),
      );
}

class DigitInput extends StatefulWidget {
  const DigitInput({
    required this.controller,
    required this.desiredLength,
    this.breakAt = 3,
    super.key,
  });

  final DigitInputController controller;
  final int desiredLength;
  final int breakAt;

  @override
  State<DigitInput> createState() => _DigitInputState();
}

class _DigitInputState extends State<DigitInput> implements TextInputClient {
  TextInputConnection? _textInputConnection;

  @override
  void initState() {
    super.initState();
    _openVirtualKeyboard();
  }

  void _openVirtualKeyboard() {
    if (_textInputConnection == null || !_textInputConnection!.attached) {
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.number,
          inputAction: Platform.isIOS ? TextInputAction.done : TextInputAction.none,
        ),
      );
    }

    _textInputConnection!.setEditingState(
      TextEditingValue(
        text: widget.controller.text,
        selection: TextSelection.collapsed(offset: widget.controller.text.length),
      ),
    );
    _textInputConnection!.show();
  }

  void _closeVirtualKeyboard() => _textInputConnection?.close();

  @override
  void dispose() {
    _closeVirtualKeyboard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _openVirtualKeyboard,
        child: SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => DigitInputPill(
              digit: widget.controller.text.length > index ? widget.controller.text[index] : null,
              highlighted: widget.controller.text.length == index,
            ),
            separatorBuilder: (context, index) =>
                SizedBox(width: (index + 1) % widget.breakAt == 0 ? 16 : 4),
            itemCount: widget.desiredLength,
          ),
        ),
      );

  @override
  void updateEditingValue(TextEditingValue value) {
    final RegExp numberRegExp = RegExp(r"^\d{0,6}$");

    if (numberRegExp.hasMatch(value.text)) {
      setState(() => widget.controller.text = value.text);
    } else {
      // flutter keeps the text editing state regardless of whether you actually used it or not.
      // so, if validation fails, we gotta set it back to what it was explicitly
      _textInputConnection?.setEditingState(
        TextEditingValue(
          text: widget.controller.text,
          selection: TextSelection.collapsed(offset: widget.controller.text.length),
        ),
      );
    }
  }

  @override
  void performAction(TextInputAction action) {}

  @override
  TextEditingValue? get currentTextEditingValue => TextEditingValue(text: widget.controller.text);

  @override
  void connectionClosed() => _textInputConnection = null;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void performSelector(String selectorName) {}

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}

  @override
  void insertContent(KeyboardInsertedContent content) {}
}
