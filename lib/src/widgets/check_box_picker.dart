import 'package:cake_wallet/src/widgets/picker_wrapper_widget.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/store/check_box_picker_store.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class CheckBoxPicker extends StatelessWidget {
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

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PickerWrapperWidget(
      children: [
        if (title.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
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
              color: Theme.of(context).dialogTheme.backgroundColor,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                  maxWidth: ResponsiveLayoutUtil.kPopupWidth,
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
                                  controller: _controller,
                                  child: itemsList(context),
                                )
                              : itemsList(context),
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

  Widget itemsList(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        controller: _controller,
        shrinkWrap: true,
        separatorBuilder: (context, index) => isSeparated
            ? Divider(
          color: Theme.of(context).extension<PickerTheme>()!.dividerColor,
          height: 1,
        )
            : const SizedBox(),
        itemCount: items.isEmpty ? 0 : items.length,
        itemBuilder: (context, index) => buildItem(context, index),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    final item = items[index];

    return GestureDetector(
      onTap: () {
        item.value = !item.value;
        onChanged(index, item.value);
      },
      child: Container(
        height: 55,
        color: Theme.of(context).dialogTheme.backgroundColor,
        padding: EdgeInsets.only(left: 24, right: 24),
        child: Row(
          children: [
            Observer(
              builder: (_) => StandardCheckbox(
                value: item.value,
                gradientBackground: true,
                borderColor: Theme.of(context).dividerColor,
                iconColor: Colors.white,
                onChanged: (value) {
                  item.value = value;
                  onChanged(index, value);
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: displayItem?.call(item) ??
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      color: item.isDisabled
                          ? Colors.grey.withOpacity(0.5)
                          : Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
            )
          ],
        ),
      ),
    );
  }
}
