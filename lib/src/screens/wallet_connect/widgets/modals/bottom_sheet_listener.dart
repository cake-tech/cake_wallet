import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:flutter/material.dart';

import '../../../../../core/wallet_connect/models/bottom_sheet_queue_item_model.dart';

class BottomSheetListener extends StatefulWidget {
  final BottomSheetService bottomSheetService;
  final Widget child;

  const BottomSheetListener({
    required this.child,
    required this.bottomSheetService,
    super.key,
  });

  @override
  BottomSheetListenerState createState() => BottomSheetListenerState();
}

class BottomSheetListenerState extends State<BottomSheetListener> {

  @override
  void initState() {
    super.initState();
    widget.bottomSheetService.currentSheet.addListener(_showBottomSheet);
  }

  @override
  void dispose() {
    widget.bottomSheetService.currentSheet.removeListener(_showBottomSheet);
    super.dispose();
  }

  Future<void> _showBottomSheet() async {
    if (widget.bottomSheetService.currentSheet.value != null) {
      BottomSheetQueueItemModel item = widget.bottomSheetService.currentSheet.value!;
      final value = await showModalBottomSheet(
        context: context,
        isDismissible: item.isModalDismissible,
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        isScrollControlled: true,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 18, 18, 19),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            child: item.widget,
          );
        },
      );
      item.completer.complete(value);
      widget.bottomSheetService.resetCurrentSheet();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
