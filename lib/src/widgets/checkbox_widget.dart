import 'package:flutter/material.dart';
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
        children: <Widget>[
          Container(
            height: 24.0,
            width: 24.0,
            margin: EdgeInsets.only(right: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: value
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20.0,
                  )
                : null,
          ),
          Expanded(
            child: Text(
              caption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        ],
      ),
    );
  }
}
