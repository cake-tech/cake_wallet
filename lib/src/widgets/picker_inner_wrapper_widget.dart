import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: TextDecoration.none,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
