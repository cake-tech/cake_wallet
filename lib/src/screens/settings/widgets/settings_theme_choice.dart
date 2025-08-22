import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';

class SettingsThemeChoicesCell extends StatelessWidget {
  SettingsThemeChoicesCell(this._displaySettingsViewModel);

  final items = ThemeList.all;

  final DisplaySettingsViewModel _displaySettingsViewModel;

  final double cellHeight = 25;
  final double cellWidth = 12;
  final double cellRadius = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(cellHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.current.color_theme,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          SizedBox(height: cellHeight),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 75,
              crossAxisSpacing: 20,
            ),
            itemBuilder: (context, index) {
              final MaterialThemeBase e = items[index];
              final currentTheme = _displaySettingsViewModel.currentTheme;
              final isSelected = currentTheme == e;

              return Padding(
                padding: EdgeInsets.all(5),
                child: Semantics(
                  label: e.toString(),
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () {
                      _displaySettingsViewModel.onThemeSelected(e);
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cellRadius),
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.primary)
                            : null,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(currentTheme.brightness == Brightness.light ? 0.1 : 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: cellWidth, vertical: cellHeight),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(cellRadius),
                                bottomLeft: Radius.circular(cellRadius),
                              ),
                              color: e.colorScheme.primary,
                            ),
                          ),
                          Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: cellWidth, vertical: cellHeight),
                            decoration: BoxDecoration(color: e.colorScheme.surface),
                          ),
                          Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: cellWidth, vertical: cellHeight),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(cellRadius),
                                bottomRight: Radius.circular(cellRadius),
                              ),
                              color: e.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
