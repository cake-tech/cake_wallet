import 'dart:ui';

import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showPersistentActionOverlay(BuildContext context, Future action, {String text = ""}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showPopUp(
      useRootNavigator: true,
      context: context,
      builder: (_) => PersistentActionOverlay(text: text),
      barrierDismissible: false);
  try {
    await action;
  } finally {
    // this way even if action throws, it'll still pop and not softlock the app
    navigator.pop();
  }
}

class PersistentActionOverlay extends StatelessWidget {
  const PersistentActionOverlay({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainer.withAlpha(80)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 36, height: 36, child: CupertinoActivityIndicator()),
                        if (text.isNotEmpty)
                          Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500))
                      ],
                    ),
                  ),
                ))),
      ),
    );
  }
}
