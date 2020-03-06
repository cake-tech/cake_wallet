import 'package:flutter/material.dart';

const largeHeight = 800;

class BaseRestoreWidget extends StatelessWidget {
  BaseRestoreWidget({
    @required this.firstRestoreButton,
    @required this.secondRestoreButton,
    this.isLargeScreen = false
  });

  final Widget firstRestoreButton;
  final Widget secondRestoreButton;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
        ),
        child: isLargeScreen
            ? Column(
              children: <Widget>[
                Flexible(
                  child: firstRestoreButton
                ),
                Flexible(
                  child: secondRestoreButton
                )
              ],
            )
            : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  firstRestoreButton,
                  secondRestoreButton
                ],
              ),
            )
    );
  }
}