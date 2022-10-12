import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';

class Picker<Item extends Object> extends StatefulWidget {
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
  PickerState createState() => PickerState<Item>(items, images, onItemSelected);
}

class PickerState<Item> extends State<Picker> {
  PickerState(this.items, this.images, this.onItemSelected);

  final Function(Item) onItemSelected;
  List<Item> items;
  List<Image> images;

  final TextEditingController searchController = TextEditingController();

  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      items = [];
      images = [];
      for (int i=0;i<widget.items.length;i++) {
        if (widget.matchingCriteria?.call(widget.items[i], searchController.text) ?? true) {
          items.add(widget.items[i] as Item);
          images.add(widget.images[i]);
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Container(
                    color: Theme.of(context).accentTextTheme!.headline6!.color!,
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
                                controller: searchController,
                                style: TextStyle(color: Theme.of(context).primaryTextTheme!.headline6!.color!),
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  prefixIcon: Image.asset("assets/images/search_icon.png"),
                                  filled: true,
                                  fillColor: Theme.of(context).accentTextTheme!.headline3!.color!,
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
                            color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
                            height: 1,
                          ),
                          if (widget.selectedAtIndex != -1) buildSelectedItem(),
                          Flexible(
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                (items?.length ?? 0) > 3 ? Scrollbar(
                                  controller: controller,
                                  child: itemsList(),
                                ) : itemsList(),
                                (widget.description?.isNotEmpty ?? false)
                                    ? Positioned(
                                        bottom: 24,
                                        left: 24,
                                        right: 24,
                                        child: Text(
                                          widget.description!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Lato',
                                            decoration: TextDecoration.none,
                                            color: Theme.of(context).primaryTextTheme!.headline6!.color!,
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
          AlertCloseButton(),
        ],
      ),
    );
  }

  Widget itemsList() {
    return Container(
      color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
      child: widget.isGridView
          ? GridView.builder(
              padding: EdgeInsets.zero,
              controller: controller,
              shrinkWrap: true,
              itemCount: items == null || items.isEmpty ? 0 : items.length,
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
                      color: Theme.of(context).accentTextTheme!.headline6!.backgroundColor!,
                      height: 1,
                    )
                  : const SizedBox(),
              itemCount: items == null || items.isEmpty ? 0 : items.length,
              itemBuilder: (context, index) => buildItem(index),
            ),
    );
  }

  Widget buildItem(int index) {
    /// don't show selected item in the list view
    if (widget.items[widget.selectedAtIndex] == items[index] && !widget.isGridView) {
      return const SizedBox();
    }

    final item = items[index];
    final image = images != null ? images[index] : null;

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
        color: Theme.of(context).accentTextTheme!.headline6!.color!,
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
                  // What a hack (item as) ? 
                  widget.displayItem?.call(item as Object) ?? item.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryTextTheme!.headline6!.color!,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSelectedItem() {
    final item = widget.items[widget.selectedAtIndex];
    final image = images != null ? widget.images[widget.selectedAtIndex] : null;

    return Container(
      height: 55,
      color: Theme.of(context).accentTextTheme!.headline6!.color!,
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
                  fontSize: 16,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryTextTheme!.headline6!.color!,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          Icon(Icons.check_circle, color: Theme.of(context).accentTextTheme!.bodyText1!.color!),
        ],
      ),
    );
  }
}
