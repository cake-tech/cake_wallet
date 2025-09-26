import 'package:flutter/material.dart';

class SimpleCheckbox extends StatefulWidget {
  SimpleCheckbox({this.onChanged});

  final Function(bool)? onChanged;

  @override
  State<SimpleCheckbox> createState() => _SimpleCheckboxState();
}

class _SimpleCheckboxState extends State<SimpleCheckbox> {
  bool initialValue = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.0,
      width: 24.0,
      child: Checkbox(
        value: initialValue,
        onChanged: (value) => setState(() {
          initialValue = value!;
          widget.onChanged?.call(value);
        }),
        checkColor: Theme.of(context).textTheme.titleLarge!.color,
        activeColor: Colors.transparent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
            color: Theme.of(context).textTheme.titleLarge!.color!, width: 1.0)),
      ),
    );
  }
}
