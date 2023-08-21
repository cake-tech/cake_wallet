import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundedCheckbox extends StatelessWidget {
  RoundedCheckbox({Key? key, required this.value}) : super(key: key);

  final bool value;

  @override
  Widget build(BuildContext context) {
    return  value
          ? Container(
              height: 20.0,
              width: 20.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50.0)),
                color: Theme.of(context).primaryColor,
              ),
              child: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.background,
                size: 14.0,
              ))
          : Offstage();
  }
}
