import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollableWithBottomSection extends StatefulWidget {
  final Widget content;
  final Widget bottomSection;
  final EdgeInsets contentPadding;
  final EdgeInsets bottomSectionPadding;

  ScrollableWithBottomSection(
      {this.content,
      this.bottomSection,
      this.contentPadding,
      this.bottomSectionPadding});

  @override
  ScrollableWithBottomSectionState createState() =>
      ScrollableWithBottomSectionState();
}

class ScrollableWithBottomSectionState
    extends State<ScrollableWithBottomSection> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        // physics:
        //     const AlwaysScrollableScrollPhysics(), //  const NeverScrollableScrollPhysics(), //
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: constraints.heightConstraints().maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: widget.contentPadding ??
                    EdgeInsets.only(left: 20, right: 20),
                child: widget.content,
              ),
              Padding(
                  padding: widget.bottomSectionPadding ??
                      EdgeInsets.only(bottom: 20, right: 20, left: 20),
                  child: widget.bottomSection)
            ],
          ),
        ),
      );
    });
  }
}
