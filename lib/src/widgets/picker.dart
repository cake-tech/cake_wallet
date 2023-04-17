// ignore_for_file: deprecated_member_use

import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cw_core/currency.dart';

class Picker<Item> extends StatefulWidget {
  Picker({
    required this.selectedAtIndex,
    required this.items,
    required this.onItemSelected,
    this.title,
    this.displayItem,
    this.images = const <Image>[],
    this.description,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.isGridView = false,
    this.isSeparated = true,
    this.hintText,
    this.matchingCriteria,
  }) : assert(hintText == null ||
            matchingCriteria !=
                null); // make sure that if the search field is enabled then there is a searching criteria provided

  final int selectedAtIndex;
  final List<Item> items;
  final List<Image> images;
  final String? title;
  final String? description;
  final Function(Item) onItemSelected;
  final MainAxisAlignment mainAxisAlignment;
  final String Function(Item)? displayItem;
  final bool isGridView;
  final bool isSeparated;
  final String? hintText;
  final bool Function(Item, String)? matchingCriteria;

  @override
  _PickerState<Item> createState() =>
      _PickerState<Item>(items, images, onItemSelected);
}

class _PickerState<Item> extends State<Picker<Item>> {
  _PickerState(this.items, this.images, this.onItemSelected);

  final Function(Item) onItemSelected;
  List<Item> items;
  List<Image> images;
  List<Item> filteredItems = [];
  List<Image> filteredImages = [];

  final TextEditingController searchController = TextEditingController();

  ScrollController controller = ScrollController();

  void clearFilteredItemsList() {
    filteredItems = List.from(
      items,
      growable: true,
    );
    filteredImages = List.from(
      images,
      growable: true,
    );

    if (widget.selectedAtIndex != -1) {
      if (widget.selectedAtIndex < filteredItems.length) {
        filteredItems.removeAt(widget.selectedAtIndex);
      }

      if (widget.selectedAtIndex < filteredImages.length) {
        filteredImages.removeAt(widget.selectedAtIndex);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    clearFilteredItemsList();

    searchController.addListener(() {
      clearFilteredItemsList();

      setState(() {
        filteredItems = List.from(items.where((element) {
          if (widget.selectedAtIndex != items.indexOf(element) &&
              (widget.matchingCriteria?.call(element, searchController.text) ??
                  true)) {
            if (images.isNotEmpty) {
              filteredImages.add(images[items.indexOf(element)]);
            }
            return true;
          }

          if (filteredImages.isNotEmpty) {
            filteredImages.remove(images[items.indexOf(element)]);
          }
          return false;
        }), growable: true);

        return;
      });
    });
  }

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

      final hasTitle = widget.title == null || widget.title!.isEmpty;

      // position the close button right below the search container
      closeButtonBottom = closeButtonBottom -
          containerBottom +
          (hasTitle ? padding : padding / 1.5);
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.title?.isNotEmpty ?? false)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Text(
                          widget.title!,
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
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        child: Container(
                          color: Theme.of(context)
                              .accentTextTheme
                              .headline6!
                              .color!,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: containerHeight,
                              maxWidth: ResponsiveLayoutUtil.kPopupWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.hintText != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: TextFormField(
                                      controller: searchController,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .primaryTextTheme
                                              .headline6!
                                              .color!),
                                      decoration: InputDecoration(
                                        hintText: widget.hintText,
                                        prefixIcon: Image.asset(
                                            "assets/images/search_icon.png"),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .accentTextTheme
                                            .headline3!
                                            .color!,
                                        alignLabelWithHint: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 4, horizontal: 16),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                            )),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                            )),
                                      ),
                                    ),
                                  ),
                                Divider(
                                  color: Theme.of(context)
                                      .accentTextTheme
                                      .headline6!
                                      .backgroundColor!,
                                  height: 1,
                                ),
                                if (widget.selectedAtIndex != -1)
                                  buildSelectedItem(widget.selectedAtIndex),
                                Flexible(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      filteredItems.length > 3
                                          ? Scrollbar(
                                              controller: controller,
                                              child: itemsList(),
                                            )
                                          : itemsList(),
                                      (widget.description?.isNotEmpty ?? false)
                                          ? Positioned(
                                              bottom: padding,
                                              left: padding,
                                              right: padding,
                                              child: Text(
                                                widget.description!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Lato',
                                                  decoration:
                                                      TextDecoration.none,
                                                  color: Theme.of(context)
                                                      .primaryTextTheme
                                                      .headline6!
                                                      .color!,
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
                    )
                  ],
                ),
                SizedBox(height: ResponsiveLayoutUtil.kPopupSpaceHeight),
                AlertCloseButton(bottom: closeButtonBottom),
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

  Widget itemsList() {
    return Container(
      color: Theme.of(context).accentTextTheme.headline6!.backgroundColor!,
      child: widget.isGridView
          ? GridView.builder(
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              itemCount: filteredItems.isEmpty ? 0 : filteredItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) => buildItem(index),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              separatorBuilder: (context, index) => widget.isSeparated
                  ? Divider(
                      color: Theme.of(context)
                          .accentTextTheme
                          .headline6!
                          .backgroundColor!,
                      height: 1,
                    )
                  : const SizedBox(),
              itemCount: filteredItems.isEmpty ? 0 : filteredItems.length,
              itemBuilder: (context, index) => buildItem(index),
            ),
    );
  }

  Widget buildItem(int index) {
    final item = filteredItems[index];
    final tag = item is Currency ? item.tag : null;

    final icon = item is Currency && item.iconPath != null
        ? Image.asset(
            item.iconPath!,
            height: 20.0,
            width: 20.0,
          )
        : null;

    final image = images.isNotEmpty ? filteredImages[index] : icon;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onItemSelected(item!);
      },
      child: Container(
        height: 55,
        color: Theme.of(context).accentTextTheme.headline6!.color!,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: widget.mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            image ?? Offstage(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: image != null ? 12 : 0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.displayItem?.call(item) ?? item.toString(),
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline6!
                              .color!,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (tag != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 35.0,
                          height: 18.0,
                          child: Center(
                            child: Text(
                              tag,
                              style: TextStyle(
                                  fontSize: 7.0,
                                  fontFamily: 'Lato',
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2!
                                      .color!),
                            ),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            //border: Border.all(color: ),
                            color: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .decorationColor!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectedItem(int index) {
    final item = items[index];
    final tag = item is Currency ? item.tag : null;

    final icon = item is Currency && item.iconPath != null
        ? Image.asset(
            item.iconPath!,
            height: 20.0,
            width: 20.0,
          )
        : null;

    final image = images.isNotEmpty ? images[index] : icon;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        height: 55,
        color: Theme.of(context).accentTextTheme.headline6!.color!,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: widget.mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            image ?? Offstage(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: image != null ? 12 : 0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.displayItem?.call(item) ?? item.toString(),
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline6!
                              .color!,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (tag != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 35.0,
                          height: 18.0,
                          child: Center(
                            child: Text(
                              tag,
                              style: TextStyle(
                                  fontSize: 7.0,
                                  fontFamily: 'Lato',
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2!
                                      .color!),
                            ),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            //border: Border.all(color: ),
                            color: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .decorationColor!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Icon(Icons.check_circle,
                color: Theme.of(context).accentTextTheme.bodyText1!.color!),
          ],
        ),
      ),
    );
  }
}
