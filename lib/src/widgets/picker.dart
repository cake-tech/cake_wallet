import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/palette.dart';

class Picker<Item extends Object> extends StatefulWidget {
  Picker({
    @required this.selectedAtIndex,
    @required this.items,
    @required this.onItemSelected,
    this.title,
    this.displayItem,
    this.images,
    this.description,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.isGridView = false,
    this.isSeparated = true,
    this.hintText,
  });

  final int selectedAtIndex;
  final List<Item> items;
  final List<Image> images;
  final String title;
  final String description;
  final Function(Item) onItemSelected;
  final MainAxisAlignment mainAxisAlignment;
  final String Function(Item) displayItem;
  final bool isGridView;
  final bool isSeparated;
  final String hintText;

  @override
  PickerState createState() => PickerState<Item>(items, images, onItemSelected);
}

class PickerState<Item> extends State<Picker> {
  PickerState(this.items, this.images, this.onItemSelected);

  final Function(Item) onItemSelected;
  final List<Item> items;
  final List<Image> images;

  final closeButton = Image.asset(
    'assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );
  ScrollController controller = ScrollController();

  final double backgroundHeight = 193;
  final double thumbHeight = 72;
  double fromTop = 0;

  @override
  Widget build(BuildContext context) {
    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset / controller.position.maxScrollExtent * (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

    final isShowScrollThumb = items != null ? items.length > 3 : false;

    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.title?.isNotEmpty ?? false)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: GestureDetector(
                  onTap: () => null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    child: Container(
                      color: Theme.of(context).accentTextTheme.title.color,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.65,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.hintText != null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    hintText: widget.hintText,
                                    prefixIcon: Image.asset("assets/images/search_icon.png"),
                                    filled: true,
                                    fillColor: const Color(0xffF2F0FA),
                                    alignLabelWithHint: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        )),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Colors.transparent,
                                        )),
                                  ),
                                ),
                              ),
                            Divider(
                              color: Theme.of(context).accentTextTheme.title.backgroundColor,
                              height: 1,
                            ),
                            if (widget.selectedAtIndex != -1) buildItem(widget.selectedAtIndex, selected: true),
                            Flexible(
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  isShowScrollThumb
                                      ? Scrollbar(
                                          controller: controller,
                                          child: itemsList(),
                                        )
                                      : itemsList(),
                                  (widget.description?.isNotEmpty ?? false)
                                      ? Positioned(
                                          bottom: 24,
                                          left: 24,
                                          right: 24,
                                          child: Text(
                                            widget.description,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Lato',
                                              decoration: TextDecoration.none,
                                              color: Theme.of(context).primaryTextTheme.title.color,
                                            ),
                                          ),
                                        )
                                      : Offstage(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          AlertCloseButton(image: closeButton)
        ],
      ),
    );
  }

  Widget itemsList() {
    if (widget.isGridView) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        controller: controller,
        itemCount: items == null ? 0 : items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
        ),
        itemBuilder: (context, index) => buildItem(index),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      controller: controller,
      shrinkWrap: true,
      separatorBuilder: (context, index) => widget.isSeparated
          ? Divider(
              color: Theme.of(context).accentTextTheme.title.backgroundColor,
              height: 1,
            )
          : const SizedBox(),
      itemCount: items == null ? 0 : items.length,
      itemBuilder: (context, index) => buildItem(index),
    );
  }

  Widget buildItem(int index, {bool selected = false}) {
    final item = items[index];
    final image = images != null ? images[index] : null;
    final isItemSelected = index == widget.selectedAtIndex;

    /// don't show selected item in the list
    if (index == widget.selectedAtIndex && selected == false) {
      return const SizedBox();
    }

    final textColor = isItemSelected ? Color(0xff815DFB) : Theme.of(context).primaryTextTheme.title.color;

    return GestureDetector(
      onTap: () {
        if (onItemSelected == null) {
          return;
        }
        Navigator.of(context).pop();
        onItemSelected(item);
      },
      child: Container(
        height: 55,
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: widget.mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            image ?? Offstage(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: image != null ? 12 : 0),
                child: Text(
                  widget.displayItem?.call(item) ?? item.toString(),
                  style: TextStyle(
                    fontSize: selected ? 16 : 14,
                    fontFamily: 'Lato',
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: Color(0xff815DFB)),
          ],
        ),
      ),
    );
  }
}
