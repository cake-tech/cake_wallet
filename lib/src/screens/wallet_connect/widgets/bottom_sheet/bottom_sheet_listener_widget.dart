import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/bottom_sheet_queue_item_model.dart';
import 'package:flutter/material.dart';

class BottomSheetListener extends StatefulWidget {
  final BottomSheetService bottomSheetService;
  final Widget child;

  const BottomSheetListener({
    required this.bottomSheetService,
    required this.child,
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
          if (item.closeAfter > 0) {
            Future.delayed(Duration(seconds: item.closeAfter), () {
              try {
                if (!mounted) return;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              } catch (e, s) {
                debugPrint('[$runtimeType] close $e $s');
              }
            });
          }
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     IconButton(
                  //       color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  //       padding: const EdgeInsets.all(0.0),
                  //       visualDensity: VisualDensity.compact,
                  //       onPressed: () {
                  //         if (Navigator.canPop(context)) {
                  //           Navigator.pop(context);
                  //         }
                  //       },
                  //       icon: Icon(
                  //         Icons.close_sharp,
                  //         color: Theme.of(context).colorScheme.onSurfaceVariant,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  Flexible(child: item.widget),
                ],
              ),
            ),
          );
        },
      );

      if (!item.completer.isCompleted) {
        item.completer.complete(value);
      }
      widget.bottomSheetService.showNext();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
