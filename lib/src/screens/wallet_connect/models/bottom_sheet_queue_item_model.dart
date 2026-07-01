import 'dart:async';

import 'package:flutter/cupertino.dart';

class BottomSheetQueueItemModel {
  final Widget widget;
  final bool isModalDismissible;
  final Completer<dynamic> completer;
  final int closeAfter;

  BottomSheetQueueItemModel({
    required this.widget,
    required this.completer,
    this.isModalDismissible = false,
    this.closeAfter = 0,
  });

  @override
  String toString() {
    return 'BottomSheetQueueItemModel(widget: $widget, completer: $completer)';
  }
}
