import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../models/bottom_sheet_queue_item_model.dart';
import '../../../utils/constants.dart';
import '../../../services/bottom_sheet_service.dart';

class BottomSheetListener extends StatefulWidget {
  final Widget child;

  const BottomSheetListener({
    super.key,
    required this.child,
  });

  @override
  BottomSheetListenerState createState() => BottomSheetListenerState();
}

class BottomSheetListenerState extends State<BottomSheetListener> {
  late final BottomSheetService _bottomSheetService;

  @override
  void initState() {
    super.initState();
    _bottomSheetService = GetIt.I<BottomSheetService>();
    _bottomSheetService.currentSheet.addListener(_showBottomSheet);
  }

  @override
  void dispose() {
    _bottomSheetService.currentSheet.removeListener(_showBottomSheet);
    super.dispose();
  }

  Future<void> _showBottomSheet() async {
    if (_bottomSheetService.currentSheet.value != null) {
      BottomSheetQueueItemModel item = _bottomSheetService.currentSheet.value!;
      final value = await showModalBottomSheet(
        context: context,
        backgroundColor: StyleConstants.clear,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: StyleConstants.layerColor1,
              borderRadius: BorderRadius.all(
                Radius.circular(
                  StyleConstants.linear16,
                ),
              ),
            ),
            padding: const EdgeInsets.all(
              StyleConstants.linear16,
            ),
            margin: const EdgeInsets.all(
              StyleConstants.linear16,
            ),
            child: item.widget,
          );
        },
      );
      item.completer.complete(value);
      _bottomSheetService.showNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
