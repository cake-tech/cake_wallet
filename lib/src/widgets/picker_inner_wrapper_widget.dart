import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';

class PickerInnerWrapperWidget extends StatelessWidget {
  PickerInnerWrapperWidget(
      {required this.children, this.title, this.itemsHeight});

  final List<Widget> children;
  final String? title;
  final double? itemsHeight;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom;
    final height = mq.size.height - bottom;

    double containerHeight = height * 0.65;
    if (bottom > 0) {
      // increase a bit or it gets too squished in the top
      containerHeight = height * 0.75;
    }

    if (title != null) {
      return PickerWrapperWidget(
        hasTitle: true,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                  decoration: TextDecoration.none,
                  color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              child: Container(
                color: Theme.of(context).dialogTheme.backgroundColor,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        itemsHeight != null && itemsHeight! <= containerHeight
                            ? itemsHeight!
                            : containerHeight,
                    maxWidth: ResponsiveLayoutUtilBase.kPopupWidth,
                  ),
                  child: Column(
                    children: children,
                  ),
                ),
              ),
            ),
          )
        ],
      );
    }

    return PickerWrapperWidget(
      hasTitle: false,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            child: Container(
              color: Theme.of(context).dialogTheme.backgroundColor,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: containerHeight,
                  maxWidth: ResponsiveLayoutUtilBase.kPopupWidth,
                ),
                child: Column(
                  children: children,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
