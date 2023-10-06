import 'dart:async';

import 'package:flutter/cupertino.dart';

class BottomSheetQueueItemModel {
  final Widget widget;
  final bool isModalDismissible;
  final Completer<dynamic> completer;

  BottomSheetQueueItemModel({
    required this.widget,
    required this.completer,
    this.isModalDismissible = false,
  });

  @override
  String toString() {
    return 'BottomSheetQueueItemModel(widget: $widget, completer: $completer)';
  }
}
