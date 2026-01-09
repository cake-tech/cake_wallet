import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/view_model/dashboard/export_option.dart';
import 'package:flutter/material.dart';

class ExportOptionsWidget extends StatefulWidget {
  const ExportOptionsWidget({
    required this.exportOptions,
    this.onClose,
    Key? key,
  }) : super(key: key);

  final Map<String, List<ExportOption>> exportOptions;
  final Function()? onClose;

  @override
  _ExportOptionsWidgetState createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget> {
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
              return _buildExportContent(context, availableHeight);
            },
          ),
          Expanded(
            child: AlertCloseButton(
              key: const ValueKey('export_options_close_button_key'),
              isPositioned: false,
              onTap: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportContent(BuildContext context, double availableHeight) {
    const sectionDivider = HorizontalSectionDivider();

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
                          'Export Transactions',
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
                      itemCount: widget.exportOptions.length,
                      separatorBuilder: (context, _) => sectionDivider,
                      itemBuilder: (_, index1) {
                        final title = widget.exportOptions.keys.elementAt(index1);
                        final section = widget.exportOptions.values.elementAt(index1);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.exportOptions.length > 1)
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
                            ListView.builder(
                              controller: null,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.length,
                              itemBuilder: (_, index2) {
                                final option = section[index2];
                                return ListTile(
                                  key: ValueKey('export_option_${index1}_${index2}'),
                                  leading: option.icon != null
                                      ? Icon(
                                          option.icon,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        )
                                      : null,
                                  title: Text(
                                    option.title,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    option.onTap();
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  hoverColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                                );
                              },
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
