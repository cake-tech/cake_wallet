import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandartSwitch extends StatefulWidget {
  const StandartSwitch({@required this.value, @required this.onTaped});

  final bool value;
  final VoidCallback onTaped;

  @override
  StandartSwitchState createState() => StandartSwitchState();
}

class StandartSwitchState extends State<StandartSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTaped,
      child: AnimatedContainer(
        padding: EdgeInsets.only(left: 2.0, right: 2.0),
        alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
        duration: Duration(milliseconds: 250),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
            color: widget.value
                ? Colors.green
                : Theme.of(context).accentTextTheme.display4.color,
            borderRadius: BorderRadius.all(Radius.circular(14.0))),
        child: Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle),
        ),
      ),
    );
  }
}
