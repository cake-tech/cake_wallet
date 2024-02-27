import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandardSwitch extends StatefulWidget {
  const StandardSwitch({required this.value, required this.onTaped});

  final bool value;
  final VoidCallback onTaped;

  @override
  StandardSwitchState createState() => StandardSwitchState();
}

class StandardSwitchState extends State<StandardSwitch> {
  @override
  Widget build(BuildContext context) {

    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onTap: widget.onTaped,
        child: AnimatedContainer(
          padding: EdgeInsets.only(left: 2.0, right: 2.0),
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          duration: Duration(milliseconds: 250),
          width: 50,
          height: 28,
          decoration: BoxDecoration(
              color: widget.value
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
              borderRadius: BorderRadius.all(Radius.circular(14.0))),
          child: Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
