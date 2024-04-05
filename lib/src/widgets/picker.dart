// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/currency.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';

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
    this.headerEnabled = true,
    this.closeOnItemSelected = true,
    this.sliderValue,
    this.customItemIndex,
    this.isWrapped = true,
    this.borderColor,
    this.onSliderChanged,
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
  final bool headerEnabled;
  final bool closeOnItemSelected;
  final double? sliderValue;
  final int? customItemIndex;
  final bool isWrapped;
  final Color? borderColor;
  final Function(double)? onSliderChanged;
  final bool Function(Item, String)? matchingCriteria;

  @override
  _PickerState<Item> createState() => _PickerState<Item>(items, images, onItemSelected);
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
              (widget.matchingCriteria?.call(element, searchController.text) ?? true)) {
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

    double containerHeight = height * 0.65;
    if (bottom > 0) {
      // increase a bit or it gets too squished in the top
      containerHeight = height * 0.75;
    }

    final content = Column (
      children: [
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.borderColor ?? Colors.transparent,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: Container(
                color: Theme.of(context).dialogTheme.backgroundColor,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: containerHeight,
                    maxWidth: ResponsiveLayoutUtilBase.kPopupWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.hintText != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SearchBarWidget(
                              searchController: searchController, hintText: widget.hintText),
                        ),
                      Divider(
                        color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
                        height: 1,
                      ),
                      if (widget.selectedAtIndex != -1 && widget.headerEnabled)
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
                                        decoration: TextDecoration.none,
                                        color:
                                            Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
    );

    if (widget.isWrapped) {
      return PickerWrapperWidget(
        hasTitle: widget.title?.isNotEmpty ?? false,
        children: [content],
      );
    } else {
      return content;
    }
  }

  Widget itemsList() {
    final itemCount = !widget.headerEnabled
        ? items.length
        : filteredItems.isEmpty
            ? 0
            : filteredItems.length;
    return Container(
      color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
      child: widget.isGridView
          ? GridView.builder(
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) =>
                  !widget.headerEnabled && widget.selectedAtIndex == index
                      ? buildSelectedItem(index)
                      : buildItem(index),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              separatorBuilder: (context, index) => widget.isSeparated
                  ? Divider(
                      color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
                      height: 1,
                    )
                  : const SizedBox(),
              itemCount: itemCount,
              itemBuilder: (context, index) =>
                  !widget.headerEnabled && widget.selectedAtIndex == index
                      ? buildSelectedItem(index)
                      : buildItem(index),
            ),
    );
  }

  Widget buildItem(int index) {
    final item = widget.headerEnabled ? filteredItems[index] : items[index];

    final tag = item is Currency ? item.tag : null;
    final icon = _getItemIcon(item);

    final image = images.isNotEmpty ? filteredImages[index] : icon;

    final isCustomItem = widget.customItemIndex != null && index == widget.customItemIndex;

    final itemContent = Row(
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
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                            color: Theme.of(context).extension<CakeScrollbarTheme>()!.thumbColor,
                          ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        //border: Border.all(color: ),
                        color: Theme.of(context).extension<CakeScrollbarTheme>()!.trackColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        if (widget.closeOnItemSelected) Navigator.of(context).pop();
        onItemSelected(item!);
      },
      child: Container(
        height: isCustomItem ? 95 : 55,
        color: Theme.of(context).dialogTheme.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: isCustomItem
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  itemContent,
                  buildSlider(index: index, isActivated: widget.selectedAtIndex == index)
                ],
              )
            : itemContent,
      ),
    );
  }

  Widget buildSelectedItem(int index) {
    final item = items[index];

    final tag = item is Currency ? item.tag : null;
    final icon = _getItemIcon(item);

    final image = images.isNotEmpty ? images[index] : icon;

    final isCustomItem = widget.customItemIndex != null && index == widget.customItemIndex;

    final itemContent = Row(
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
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                            color: Theme.of(context).extension<CakeScrollbarTheme>()!.thumbColor,
                          ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        //border: Border.all(color: ),
                        color: Theme.of(context).extension<CakeScrollbarTheme>()!.trackColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
      ],
    );

    return GestureDetector(
      onTap: () {
        if (widget.closeOnItemSelected) Navigator.of(context).pop();
      },
      child: Container(
        height: isCustomItem ? 95 : 55,
        color: Theme.of(context).dialogTheme.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: isCustomItem
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  itemContent,
                  buildSlider(index: index, isActivated: widget.selectedAtIndex == index)
                ],
              )
            : itemContent,
      ),
    );
  }

  Widget? _getItemIcon(Item item) {
    if (item is Currency) {
      if (item.iconPath != null) {
        return Image.asset(
          item.iconPath!,
          height: 20.0,
          width: 20.0,
        );
      } else {
        return Container(
          height: 20.0,
          width: 20.0,
          child: Center(
            child: Text(
              item.name.substring(0, min(item.name.length, 2)).toUpperCase(),
              style: TextStyle(fontSize: 11),
            ),
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade400,
          ),
        );
      }
    }

    return null;
  }

  Widget buildSlider({required int index, required bool isActivated}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Slider(
            value: widget.sliderValue ?? 2,
            onChanged: isActivated ? widget.onSliderChanged : null,
            min: 2,
            max: 100,
            divisions: 100,
          ),
        ),
      ],
    );
  }
}
