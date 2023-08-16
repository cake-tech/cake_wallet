import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';

class CheckboxWidget extends StatefulWidget {
  CheckboxWidget({required this.value, required this.caption, required this.onChanged});

  final bool value;
  final String caption;
  final Function(bool) onChanged;

  @override
  CheckboxWidgetState createState() => CheckboxWidgetState(value, caption, onChanged);
}

class CheckboxWidgetState extends State<CheckboxWidget> {
  CheckboxWidgetState(this.value, this.caption, this.onChanged);

  bool value;
  String caption;
  Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        value = !value;
        onChanged(value);
        setState(() {});
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 24.0,
            width: 24.0,
            margin: EdgeInsets.only(right: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: value
                    ? Palette.blueCraiola
                    : Theme.of(context).extension<FilterTheme>()!.checkboxBoundsColor,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              color: Theme.of(context).colorScheme.background,
            ),
            child: value
                ? Icon(
                    Icons.check,
                    color: Colors.blue,
                    size: 20.0,
                  )
                : null,
          ),
          Expanded(
            child: Text(
              caption,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ),
          )
        ],
      )
    );
  }
}
