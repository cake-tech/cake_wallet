import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/monero/get_height_by_date.dart';

class BlockchainHeightWidget extends StatefulWidget {
  BlockchainHeightWidget({GlobalKey key, this.onHeightChange})
      : super(key: key);

  final Function(int) onHeightChange;

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
      try {
        _changeHeight(restoreHeightController.text != null &&
                restoreHeightController.text.isNotEmpty
            ? int.parse(restoreHeightController.text)
            : 0);
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
              child: TextFormField(
                style: TextStyle(
                    fontSize: 16.0,
                    color: Theme.of(context).primaryTextTheme.title.color),
                controller: restoreHeightController,
                keyboardType: TextInputType.numberWithOptions(
                    signed: false, decimal: false),
                decoration: InputDecoration(
                    hintStyle: TextStyle(
                        color: Theme.of(context).primaryTextTheme.caption.color,
                        fontSize: 16),
                    hintText: S.of(context).widgets_restore_from_blockheight,
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor, width: 1.0)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1.0))),
              ),
            ))
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 15, bottom: 15),
          child: Text(
            S.of(context).widgets_or,
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryTextTheme.title.color),
          ),
        ),
        Row(
          children: <Widget>[
            Flexible(
                child: Container(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: IgnorePointer(
                  child: TextFormField(
                    style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).primaryTextTheme.title.color),
                    decoration: InputDecoration(
                        hintStyle: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .color,
                            fontSize: 16),
                        hintText: S.of(context).widgets_restore_from_date,
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.0)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.0))),
                    controller: dateController,
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
              ),
            ))
          ],
        ),
      ],
    );
  }

  Future _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: now.subtract(Duration(days: 1)),
        firstDate: DateTime(2014, DateTime.april),
        lastDate: now);

    if (date != null) {
      final height = getHeigthByDate(date: date);

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
