import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RecipientDotRow extends StatefulWidget {
  const RecipientDotRow(
      {super.key, required this.numDots, required this.selectedDot, required this.onSelected});

  final int numDots;
  final int selectedDot;
  final Function(int) onSelected;

  @override
  State<RecipientDotRow> createState() => _RecipientDotRowState();
}

class _RecipientDotRowState extends State<RecipientDotRow> {
  static const double _outputDotSize = 36;
  static const double _outputDotSpacing = 8;
  late ScrollController _outputDotsController;
  bool _wasScrollable = false;

  @override
  void initState() {
    super.initState();
    _outputDotsController = ScrollController();
  }

  @override
  void didUpdateWidget(RecipientDotRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.numDots != oldWidget.numDots) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_outputDotsController.hasClients) {
          _outputDotsController.animateTo(_outputDotsController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;

        final double itemExtent = _outputDotSize + _outputDotSpacing;
        final totalContentWidth = (widget.numDots * itemExtent) - _outputDotSpacing;
        final isScrollable = totalContentWidth > viewportWidth;

        final sidePadding = isScrollable ? viewportWidth * 0.175 : 0.0;

        if (isScrollable && !_wasScrollable) {
          _outputDotsController
              .jumpTo((widget.numDots * 0.175) * itemExtent - (_outputDotSpacing * 1.35));
        }

        _wasScrollable = isScrollable;

        return SizedBox(
          height: _outputDotSize,
          width: double.infinity,
          child: Center(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: ListView.builder(
                key: ValueKey(_outputDotsController),
                controller: _outputDotsController,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                physics: BouncingScrollPhysics(),
                itemCount: widget.numDots,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _outputDotsController,
                    builder: (context, child) {
                      double scale = 1.0;

                      if (isScrollable) {
                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                        final RenderBox? viewportBox = context
                            .findAncestorRenderObjectOfType<RenderProxyBoxWithHitTestBehavior>();

                        if (box != null && viewportBox != null) {
                          final dotPosition = box.localToGlobal(Offset.zero, ancestor: viewportBox);
                          final dotCenter = dotPosition.dx + (_outputDotSize / 2);
                          final viewportCenter = viewportWidth / 2;
                          final distance = (dotCenter - viewportCenter).abs();
                          final threshold = viewportWidth * 0.35;
                          final maxDistance = viewportWidth / 2;

                          if (distance > threshold) {
                            final t = ((distance - threshold) / (maxDistance - threshold))
                                .clamp(0.0, 1.0);
                            scale = 1.0 - (t * 0.6);
                          }
                        } else {
                          if (index == widget.numDots - 1) scale = 0.0;
                        }
                      }

                      return Transform.scale(
                          scale: scale,
                          child: RecipientDot(
                            size: _outputDotSize,
                            spacing: _outputDotSpacing,
                            index: index,
                            onTap: () {
                              if (scale != 1.0) {
                                _outputDotsController.animateTo(index * _outputDotSize,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic);
                              }
                              widget.onSelected(index);
                            },
                            selected: index == widget.selectedDot,
                          ));
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class RecipientDot extends StatefulWidget {
  const RecipientDot(
      {super.key,
      required this.size,
      required this.spacing,
      required this.index,
      required this.onTap,
      required this.selected});

  final double size;
  final double spacing;
  final int index;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<RecipientDot> createState() => _RecipientDotState();
}

class _RecipientDotState extends State<RecipientDot> {
  bool _created = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _created = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + widget.spacing,
      height: widget.size,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            top: _created ? 0 : widget.size,
            child: Material(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: GestureDetector(
                  key: ValueKey(widget.selected),
                  onTap: widget.onTap,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text((widget.index+1).toString(),
                    style: TextStyle(
                      color: widget.selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize:14,fontWeight: FontWeight.w500
                    ),),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
