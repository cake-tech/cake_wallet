import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class BlockchainHeightWidget extends StatefulWidget {
  BlockchainHeightWidget({
    GlobalKey? key,
    this.onHeightChange,
    this.focusNode,
    this.onHeightOrDateEntered,
    this.hasDatePicker = true})
      : super(key: key);

  final Function(int)? onHeightChange;
  final Function(bool)? onHeightOrDateEntered;
  final FocusNode? focusNode;
  final bool hasDatePicker;

  @override
  State<StatefulWidget> createState() => BlockchainHeightState();
}

class BlockchainHeightState extends State<BlockchainHeightWidget> {
  final dateController = TextEditingController();
  final restoreHeightController = TextEditingController();

  int get height => _height;
  int _height = 0;

  @override
  void initState() {
    restoreHeightController.addListener(() {
      if (restoreHeightController.text.isNotEmpty) {
        widget.onHeightOrDateEntered?.call(true);
      } else {
        widget.onHeightOrDateEntered?.call(false);
        dateController.text = '';
      }
      try {
        _changeHeight(
            restoreHeightController.text.isNotEmpty ? int.parse(restoreHeightController.text) : 0);
      } catch (_) {
        _changeHeight(0);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
                child: Container(
                    padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: BaseTextFormField(
                      focusNode: widget.focusNode,
                      controller: restoreHeightController,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      hintText: S.of(context).widgets_restore_from_blockheight,
                    )))
          ],
        ),
        if (widget.hasDatePicker) ...[
          Padding(
            padding: EdgeInsets.only(top: 15, bottom: 15),
            child: Text(
              S.of(context).widgets_or,
              style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).extension<CakeTextTheme>()!.titleColor),
            ),
          ),
          Row(
            children: <Widget>[
              Flexible(
                  child: Container(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: IgnorePointer(
                      child: BaseTextFormField(
                    controller: dateController,
                    hintText: S.of(context).widgets_restore_from_date,
                  )),
                ),
              ))
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 40, right: 40, top: 24),
            child: Text(
              S.of(context).restore_from_date_or_blockheight,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).hintColor
              ),
            ),
          )
        ]
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await getDate(
        context: context,
        initialDate: now.subtract(Duration(days: 1)),
        firstDate: DateTime(2014, DateTime.may),
        lastDate: now);

    if (date != null) {
      final height = monero!.getHeightByDate(date: date);
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(date);
        restoreHeightController.text = '$height';
        _changeHeight(height);
      });
    }
  }

  void _changeHeight(int height) {
    _height = height;
    widget.onHeightChange?.call(height);
  }
}
