import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class TextFieldListRow extends StatefulWidget {
  TextFieldListRow({
    required this.title,
    required this.value,
    this.titleFontSize = 14,
    this.valueFontSize = 16,
    this.onSubmitted,
    super.key,
  });

  final String title;
  final String value;
  final double titleFontSize;
  final double valueFontSize;
  final Function(String value)? onSubmitted;

  @override
  _TextFieldListRowState createState() => _TextFieldListRowState();
}

class _TextFieldListRowState extends State<TextFieldListRow> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onSubmitted?.call(_textController.text);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: widget.titleFontSize,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 4),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              maxLines: null,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: widget.valueFontSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                isDense: true,
                contentPadding: EdgeInsets.only(
                  top: 12,
                  bottom: 0,
                  left: 8,
                  right: 8,
                ),
                hintText: S.of(context).enter_your_note,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: widget.valueFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.0,
                  ),
                ),
              ),
              onSubmitted: (value) {
                widget.onSubmitted?.call(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
