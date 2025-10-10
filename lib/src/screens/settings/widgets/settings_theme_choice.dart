import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/theme_classes/black_theme.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SettingsThemeChoicesCell extends StatelessWidget {
  SettingsThemeChoicesCell(this._displaySettingsViewModel);

  final DisplaySettingsViewModel _displaySettingsViewModel;

  final double cellHeight = 25;
  final double cellWidth = 12;
  final double cellRadius = 8;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final availableThemes = _displaySettingsViewModel.availableThemes;
        final currentTheme = _displaySettingsViewModel.currentTheme;
        final availableAccentColors = _displaySettingsViewModel.availableAccentColors;

        return Container(
          height: getHeight(currentTheme, currentTheme.hasAccentColors),
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: availableThemes.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final MaterialThemeBase theme = availableThemes[index];
                    final isSelected = _displaySettingsViewModel.isThemeSelected(theme);

                    return Semantics(
                      label: theme.toString(),
                      selected: isSelected,
                      child: GestureDetector(
                        onTap: () {
                          _displaySettingsViewModel.onThemeSelected(theme);
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cellRadius),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    strokeAlign: BorderSide.strokeAlignOutside)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cellRadius),
                            child: CakeImageWidget(
                              imageUrl: _displaySettingsViewModel.getImageForTheme(theme),
                              fit: BoxFit.cover,
                              height: 200,
                              width: 120,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_displaySettingsViewModel.currentTheme.hasAccentColors) ...[
                SizedBox(height: cellHeight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).accent_color,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Container(
                      height: 40,
                      child: Row(
                        children: availableAccentColors.map((accentColor) {
                          final isSelected = _displaySettingsViewModel
                              .isAccentColorSelected(accentColor.name.toLowerCase());
                          return GestureDetector(
                            onTap: () {
                              _displaySettingsViewModel
                                  .onAccentColorSelected(accentColor.name.toLowerCase());
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              margin: EdgeInsets.only(right: 11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        width: 3)
                                    : null,
                                color: accentColor.color,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
              if (_displaySettingsViewModel.currentTheme is BlackTheme)
                SettingsSwitcherCell(
                  title: S.current.oled_mode,
                  value: _displaySettingsViewModel.isBlackThemeOledEnabled,
                  onValueChange: (_, bool value) {
                    _displaySettingsViewModel.setBlackThemeOled(value);
                  },
                  padding: EdgeInsets.zero,
                  switchBackgroundColor: currentTheme.colorScheme.secondaryContainer,
                ),
            ],
          ),
        );
      },
    );
  }

  double getHeight(MaterialThemeBase theme, bool hasAccentColors) {
    if (theme is BlackTheme && hasAccentColors) return 356;

    if (hasAccentColors) return 306;

    return 236;
  }
}
