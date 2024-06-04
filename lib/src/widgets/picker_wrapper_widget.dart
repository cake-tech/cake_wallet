import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';

class PickerWrapperWidget extends StatelessWidget {
  PickerWrapperWidget({required this.children, this.hasTitle = false, this.onClose});

  final List<Widget> children;
  final bool hasTitle;
  final Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final double padding = 24;

    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom;
    final height = mq.size.height - bottom;
    final screenCenter = height / 2;

    double closeButtonBottom = 60;
    double containerHeight = height * 0.65;
    if (bottom > 0) {
      // increase a bit or it gets too squished in the top
      containerHeight = height * 0.75;

      final containerCenter = containerHeight / 2;
      final containerBottom = screenCenter - containerCenter;

      // position the close button right below the search container
      closeButtonBottom = closeButtonBottom -
          containerBottom + (!hasTitle ? padding : padding / 1.5);
    }

    return AlertBackground(
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
                SizedBox(height: ResponsiveLayoutUtilBase.kPopupSpaceHeight),
                AlertCloseButton(bottom: closeButtonBottom, onTap: onClose),
              ],
            ),
          ),
          // gives the extra spacing using MediaQuery.viewInsets.bottom
          // to simulate a keyboard area
          SizedBox(
            height: bottom,
          )
        ],
      ),
    );
  }
}
