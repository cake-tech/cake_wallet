import 'dart:async';
import 'dart:collection';

import 'package:cake_wallet/src/screens/wallet_connect/models/bottom_sheet_queue_item_model.dart';
import 'package:flutter/material.dart';

abstract class BottomSheetService {
  abstract final ValueNotifier<BottomSheetQueueItemModel?> currentSheet;

  Future<dynamic> queueBottomSheet({
    required Widget widget,
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
  }) async {
    // Create the bottom sheet queue item
    final completer = Completer<dynamic>();
    final queueItem = BottomSheetQueueItemModel(
      widget: widget,
      completer: completer,
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
