import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollableWithBottomSection extends StatefulWidget {
  ScrollableWithBottomSection(
      {required this.content,
      required this.bottomSection,
      this.contentPadding,
      this.bottomSectionPadding});

  final Widget content;
  final Widget bottomSection;
  final EdgeInsets? contentPadding;
  final EdgeInsets? bottomSectionPadding;

  @override
  ScrollableWithBottomSectionState createState() => ScrollableWithBottomSectionState();
}

class ScrollableWithBottomSectionState extends State<ScrollableWithBottomSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: widget.contentPadding ?? EdgeInsets.only(left: 20, right: 20),
              child: widget.content,
            ),
          ),
        ),
        Padding(
          padding: widget.bottomSectionPadding?.copyWith(top: 10) ??
              EdgeInsets.only(top: 10, bottom: 20, right: 20, left: 20),
          child: widget.bottomSection,
        ),
      ],
    );
  }
}
