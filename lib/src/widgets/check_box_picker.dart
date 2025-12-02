import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';

class CheckBoxPicker extends StatefulWidget {
  CheckBoxPicker({
    required this.items,
    required this.onChanged,
    required this.title,
    this.displayItem,
    this.isSeparated = true,
  });

  final List<CheckBoxItem> items;
  final String title;
  final Widget Function(CheckBoxItem)? displayItem;
  final bool isSeparated;
  final Function(int, bool) onChanged;

  @override
  CheckBoxPickerState createState() => CheckBoxPickerState(items);
}

class CheckBoxPickerState extends State<CheckBoxPicker> {
  CheckBoxPickerState(this.items);

  final List<CheckBoxItem> items;

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PickerWrapperWidget(
      children: [
        if (widget.title.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.title,
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
          padding: EdgeInsets.only(left: 24, right: 24, top: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                  maxWidth: ResponsiveLayoutUtilBase.kPopupWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          items.length > 3
                              ? Scrollbar(
                                  controller: controller,
                                  child: itemsList(),
                                )
                              : itemsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget itemsList() {
    return Container(
      color: Theme.of(context).colorScheme.outlineVariant,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        controller: controller,
        shrinkWrap: true,
        separatorBuilder: (context, index) => widget.isSeparated
            ? Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
              )
            : const SizedBox(),
        itemCount: items.isEmpty ? 0 : items.length,
        itemBuilder: (context, index) => buildItem(index),
      ),
    );
  }

  Widget buildItem(int index) {
    final item = items[index];

    return GestureDetector(
      onTap: () {
        bool newValue = !item.value;
        item.value = newValue;
        widget.onChanged(index, newValue);
        setState(() {});
      },
      child: Container(
        height: 55,
        color: Theme.of(context).colorScheme.surfaceContainer,
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Row(
          children: [
            StandardCheckbox(
              value: item.value,
              gradientBackground: true,
              borderColor: Theme.of(context).colorScheme.outlineVariant,
              iconColor: Theme.of(context).colorScheme.onPrimary,
              onChanged: (bool? value) {
                if (value == null) {
                  return;
                }

                item.value = value;
                widget.onChanged(index, value);
                setState(() {});
              },
            ),
            SizedBox(width: 16),
            widget.displayItem?.call(item) ??
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.isDisabled
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: TextDecoration.none,
                      ),
                )
          ],
        ),
      ),
    );
  }
}

class CheckBoxItem {
  CheckBoxItem(this.title, this.value, {this.isDisabled = false});

  final String title;
  final bool isDisabled;
  bool value;
}
