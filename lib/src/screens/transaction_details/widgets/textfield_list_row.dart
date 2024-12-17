import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
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
      color: Theme.of(context).colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              style: TextStyle(
                fontSize: widget.titleFontSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
              ),
              textAlign: TextAlign.left,
            ),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              maxLines: null,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: widget.valueFontSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(top: 12, bottom: 0),
                hintText: S.of(context).enter_your_note,
                hintStyle: TextStyle(
                  fontSize: widget.valueFontSize,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
                ),
                border: InputBorder.none,
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
