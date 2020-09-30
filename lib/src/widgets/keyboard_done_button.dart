import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyboardDoneButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // FIXME: Add translation
    return CupertinoButton(
      padding: EdgeInsets.only(right: 24.0, top: 8.0, bottom: 8.0),
      onPressed: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Text(
          'Done',
          style: TextStyle(color: Colors.blueAccent,fontWeight: FontWeight.bold)
      ),
    );
  }
}