import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollableWithBottomSection extends StatefulWidget {
  ScrollableWithBottomSection({
    required this.content,
    required this.bottomSection,
    this.topSection,
    this.contentPadding,
    this.bottomSectionPadding,
    this.topSectionPadding,
    this.scrollableKey,
  });

  final Widget content;
  final Widget bottomSection;
  final Widget? topSection;
  final EdgeInsets? contentPadding;
  final EdgeInsets? bottomSectionPadding;
  final EdgeInsets? topSectionPadding;
  final Key? scrollableKey;

  @override
  ScrollableWithBottomSectionState createState() => ScrollableWithBottomSectionState();
}

class ScrollableWithBottomSectionState extends State<ScrollableWithBottomSection> {
  @override
  Widget build(BuildContext context) {

    const rlPadding = FeatureFlag.hasNewUi ? 0.0 : 20.0;

    return Column(
      children: [
        if (widget.topSection != null)
          Padding(
            padding: widget.topSectionPadding?.copyWith(top: 10) ??
                EdgeInsets.only(top: 10, bottom: 20, right: rlPadding, left: rlPadding),
            child: widget.topSection,
          ),
        Expanded(
          child: SingleChildScrollView(
            key: widget.scrollableKey,
            child: !FeatureFlag.hasNewUi ? Padding(
              padding: widget.contentPadding ?? EdgeInsets.only(left: rlPadding, right: rlPadding),
              child: widget.content,
            )
            : widget.content
          ),
        ),
        Padding(
          padding: widget.bottomSectionPadding?.copyWith(top: 10) ??
              EdgeInsets.only(top: 10, bottom: 24, right: rlPadding, left: rlPadding),
          child: widget.bottomSection,
        ),
      ],
    );
  }
}
