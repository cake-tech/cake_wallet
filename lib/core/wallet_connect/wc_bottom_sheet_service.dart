import 'dart:async';
import 'package:cake_wallet/core/wallet_connect/models/bottom_sheet_queue_item_model.dart';
import 'package:flutter/material.dart';

abstract class BottomSheetService {
  abstract final ValueNotifier<BottomSheetQueueItemModel?> currentSheet;

  Future<dynamic> queueBottomSheet({
    required Widget widget,
    bool isModalDismissible = false,
  });

  void resetCurrentSheet();
}

class BottomSheetServiceImpl implements BottomSheetService {

  @override
  final ValueNotifier<BottomSheetQueueItemModel?> currentSheet = ValueNotifier(null);

  @override
  Future<dynamic> queueBottomSheet({
    required Widget widget,
    bool isModalDismissible = false,
  }) async {
    // Create the bottom sheet queue item
    final completer = Completer<dynamic>();
    final queueItem = BottomSheetQueueItemModel(
      widget: widget,
      completer: completer,
      isModalDismissible: isModalDismissible,
    );

    currentSheet.value = queueItem;

    return await completer.future;
  }

  @override
  void resetCurrentSheet() {
    currentSheet.value = null;
  }
}
