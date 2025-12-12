import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LineTabSwitcher extends StatefulWidget {
  const LineTabSwitcher({
    super.key,
    required this.tabs,
    required this.onTabChange,
    required this.selectedTab,
  });

  final List<String> tabs;
  final void Function(int index) onTabChange;
  final int selectedTab;

  @override
  State<LineTabSwitcher> createState() => _LineTabSwitcherState();
}

class _LineTabSwitcherState extends State<LineTabSwitcher> {
  List<GlobalKey> textWidgetKeys = [];
  List<Size> textWidgetSizes = [];
  bool textWidgetsMeasured = false;

  double _calcBarLeft() {
    double left = 0;

    if (textWidgetKeys.isEmpty || textWidgetSizes.isEmpty) {
      return 0;
    }

    for (int i = 0; i < widget.selectedTab; i++) {
      left += textWidgetSizes[i].width + 16.0;
    }

    left += 8.0;

    return left;
  }

  @override
  void initState() {
    super.initState();
    textWidgetKeys = List.generate(widget.tabs.length, (index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => measure());
  }

  void measure() {
    setState(() {
      textWidgetSizes = textWidgetKeys
          .map((k) => k.currentContext!.size)
          .whereType<Size>()
          .toList();
      textWidgetsMeasured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!textWidgetsMeasured) {
      WidgetsBinding.instance.addPostFrameCallback((_) => measure());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 40,
          child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  widget.onTabChange(index);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 150),
                      style: DefaultTextStyle.of(context).style.copyWith(
                        inherit: true,
                        fontSize: 22,
                        color: widget.selectedTab == index
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.tabs[index],
                          key: textWidgetKeys[index],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          width: 200,
          height: 2,
          child: Stack(
            children: [
              AnimatedPositioned(
                curve: Curves.easeOut,
                left: _calcBarLeft(),
                bottom: 0,
                duration: Duration(milliseconds: 150),
                child: AnimatedSize(
                  duration: Duration(milliseconds: 150),
                  child: Container(
                    height: 2,
                    width: textWidgetSizes.isEmpty
                        ? 0
                        : textWidgetSizes[widget.selectedTab].width,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
