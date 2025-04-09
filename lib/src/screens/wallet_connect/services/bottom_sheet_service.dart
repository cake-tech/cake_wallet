import 'dart:async';
import 'dart:collection';
import 'package:cake_wallet/src/screens/wallet_connect/models/bottom_sheet_queue_item_model.dart';
import 'package:flutter/material.dart';

enum WCBottomSheetResult { reject, one, all }

abstract class BottomSheetService {
  abstract final ValueNotifier<BottomSheetQueueItemModel?> currentSheet;

  Future<dynamic> queueBottomSheet({
    required Widget widget,
    bool isModalDismissible = false,
    int closeAfter = 0,
  });

  void showNext();
}

class BottomSheetServiceImpl implements BottomSheetService {
  Queue<BottomSheetQueueItemModel> queue = Queue<BottomSheetQueueItemModel>();

  @override
  final ValueNotifier<BottomSheetQueueItemModel?> currentSheet = ValueNotifier(null);

  @override
  Future<dynamic> queueBottomSheet({
    required Widget widget,
    int closeAfter = 0,
    bool isModalDismissible = false,
  }) async {
    // Create the bottom sheet queue item
    final completer = Completer<dynamic>();
    final queueItem = BottomSheetQueueItemModel(
      widget: widget,
      completer: completer,
      closeAfter: closeAfter,
      isModalDismissible: isModalDismissible,
    );

    // If the current sheet it null, set it to the queue item
    if (currentSheet.value == null) {
      currentSheet.value = queueItem;
    } else {
      // Otherwise, add it to the queue
      queue.add(queueItem);
    }

    // Return the future
    return await completer.future;
  }

  @override
  void showNext() {
    if (queue.isEmpty) {
      currentSheet.value = null;
    } else {
      currentSheet.value = queue.removeFirst();
    }
  }
}
