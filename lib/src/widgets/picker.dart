// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/material.dart';
import 'package:cw_core/currency.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';

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
    this.minValue,
    this.maxValue,
    this.customItemIndex,
    this.isWrapped = true,
    this.borderColor,
    this.onSliderChanged,
    this.matchingCriteria,
  }) : assert(hintText == null || matchingCriteria != null) {
    // make sure that if the search field is enabled then there is a searching criteria provided
    if (sliderValue != null && maxValue != null) {
      if (sliderValue! > maxValue!) {
        sliderValue = maxValue;
      }
    }
  }

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
  double? sliderValue;
  final double? minValue;
  final int? customItemIndex;
  final bool isWrapped;
  final Color? borderColor;
  final Function(double)? onSliderChanged;
  final bool Function(Item, String)? matchingCriteria;
  final double? maxValue;

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

    final content = Column(
      children: [
        if (widget.title?.isNotEmpty ?? false)
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              key: ValueKey('picker_title_text_key'),
              widget.title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.surface,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: containerHeight,
                    maxWidth: ResponsiveLayoutUtilBase.kPopupWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.hintText != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SearchBarWidget(
                            key: ValueKey('picker_search_bar_key'),
                            searchController: searchController,
                            hintText: widget.hintText,
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          height: 1,
                        ),
                      ],
                      if (widget.selectedAtIndex != -1 && widget.headerEnabled)
                        buildSelectedItem(widget.selectedAtIndex),
                      Flexible(
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            filteredItems.length > 3
                                ? Scrollbar(
                                    key: ValueKey('picker_scrollbar_key'),
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
                                      key: ValueKey('picker_descriptinon_text_key'),
                                      widget.description!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
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
        key: ValueKey('picker_wrapper_widget_key'),
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
      color: Theme.of(context).colorScheme.outlineVariant,
      child: widget.isGridView
          ? GridView.builder(
              key: ValueKey('picker_items_grid_view_key'),
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
              key: ValueKey('picker_items_list_view_key'),
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              separatorBuilder: (context, index) => widget.isSeparated
                  ? Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
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

  String _getItemName(Item item) {
    String itemName;
    if (item is Currency) {
      itemName = item.name;
    } else if (item is TransactionPriority) {
      itemName = item.title;
    } else if (item is MoneroSeedType) {
      itemName = item.title;
    } else {
      itemName = '';
    }

    return itemName;
  }

  Widget buildItem(int index) {
    final item = widget.headerEnabled ? filteredItems[index] : items[index];

    final tag = item is Currency ? item.tag : null;
    final itemName = _getItemName(item);

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
                    key: ValueKey('picker_items_index_${itemName}_text_key'),
                    widget.displayItem?.call(item) ?? item.toString(),
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
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
                          key: ValueKey('picker_items_index_${index}_tag_key'),
                          tag,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 7.0,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        //border: Border.all(color: ),
                        color: Theme.of(context).colorScheme.surfaceVariant,
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
      key: ValueKey('picker_items_index_${itemName}_button_key'),
      onTap: () {
        if (widget.closeOnItemSelected) Navigator.of(context).pop();
        onItemSelected(item!);
      },
      child: Container(
        height: isCustomItem ? 95 : 55,
        color: Theme.of(context).colorScheme.surface,
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
    final itemName = _getItemName(item);
    final icon = _getItemIcon(item);

    final image = images.isNotEmpty ? images[index] : icon;

    final isCustomItem = widget.customItemIndex != null && index == widget.customItemIndex;

    final itemContent = Row(
      key: ValueKey('picker_selected_item_row_key'),
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
                    key: ValueKey('picker_items_index_${itemName}_selected_item_text_key'),
                    widget.displayItem?.call(item) ?? item.toString(),
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
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
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 7.0,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        //border: Border.all(color: ),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
      ],
    );

    return GestureDetector(
      key: ValueKey('picker_items_index_${itemName}_selected_item_button_key'),
      onTap: () {
        if (widget.closeOnItemSelected) Navigator.of(context).pop();
      },
      child: Container(
        height: isCustomItem ? 95 : 55,
        color: Theme.of(context).colorScheme.surface,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
            ),
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        );
      }
    }

    return null;
  }

  Widget buildSlider({required int index, required bool isActivated}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: <Widget>[
        Expanded(
          child: Slider(
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: isDarkMode
                ? CustomThemeColors.toggleColorOffStateDark
                : CustomThemeColors.toggleColorOffStateLight,
            thumbColor: CustomThemeColors.toggleKnobStateColorLight,
            value: widget.sliderValue == null || widget.sliderValue! < 1 ? 1 : widget.sliderValue!,
            onChanged: isActivated ? widget.onSliderChanged : null,
            min: widget.minValue ?? 1,
            max: (widget.maxValue == null || widget.maxValue! < 1) ? 100 : widget.maxValue!,
            divisions: 100,
          ),
        ),
      ],
    );
  }
}
