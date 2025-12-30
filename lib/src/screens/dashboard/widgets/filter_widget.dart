import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_tile.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class FilterWidget extends StatefulWidget {
  const FilterWidget({required this.filterItems, this.onClose, Key? key}) : super(key: key);

  final Map<String, List<FilterItem>> filterItems;
  final Function()? onClose;

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          LayoutBuilder(
            builder: (context, constraints) {
              double availableHeight = constraints.maxHeight;
              return _buildFilterContent(context, availableHeight);
            },
          ),
          Expanded(
            child: AlertCloseButton(
              key: const ValueKey('filter_wrapper_close_button_key'),
              isPositioned: false,
              onTap: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent(BuildContext context, double availableHeight) {
    const sectionDivider = HorizontalSectionDivider();

    const double totalHeaderHeight = 73;
    const double filterTileMinHeight = 40;
    double availableHeightForItems = availableHeight - totalHeaderHeight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          S.of(context).filter_by,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    sectionDivider,
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.filterItems.length,
                      separatorBuilder: (context, _) => sectionDivider,
                      itemBuilder: (_, index1) {
                        final title = widget.filterItems.keys.elementAt(index1);
                        final section = widget.filterItems.values.elementAt(index1);

                        final double itemHeight =
                            availableHeightForItems / widget.filterItems.length;

                        final isSectionScrollable =
                            (itemHeight < (section.length * filterTileMinHeight));

                        final Widget sectionListView = ListView.builder(
                          controller: isSectionScrollable ? _scrollController : null,
                          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                          shrinkWrap: isSectionScrollable ? false : true,
                          physics: isSectionScrollable
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: section.length,
                          itemBuilder: (_, index2) {
                            final item = section[index2];
                            final content = Observer(
                              builder: (_) => StandardCheckbox(
                                value: item.value(),
                                caption: item.caption,
                                gradientBackground: true,
                                borderColor: Theme.of(context).colorScheme.outlineVariant,
                                iconColor: Theme.of(context).colorScheme.onSurface,
                                onChanged: (value) => item.onChanged(),
                              ),
                            );
                            return FilterTile(
                              child: content,
                            );
                          },
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            Container(
                              height: isSectionScrollable ? itemHeight - totalHeaderHeight : null,
                              child: isSectionScrollable
                                  ? Scrollbar(
                                      controller: _scrollController,
                                      thumbVisibility: true,
                                      child: sectionListView,
                                    )
                                  : sectionListView,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
