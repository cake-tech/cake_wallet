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

  final double cellHeight = 12;
  final double cellWidth = 12;
  final double cellRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final availableThemes = _displaySettingsViewModel.availableThemes;
        final currentTheme = _displaySettingsViewModel.currentTheme;
        final availableAccentColors = _displaySettingsViewModel.availableAccentColors;
        final screenHeight = MediaQuery.of(context).size.height;

        final previewHeight = _getResponsivePreviewHeight(screenHeight);
        final previewWidth = previewHeight * 0.6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: getHeight(context, currentTheme, currentTheme.hasAccentColors),
          padding: EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: previewHeight,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(right: 24),
                          decoration: ShapeDecoration(
                            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(cellRadius),
                            side: BorderSide(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    strokeAlign: BorderSide.strokeAlignOutside)
                          )),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cellRadius),
                            child: CakeImageWidget(
                              imageUrl: _displaySettingsViewModel.getImageForTheme(theme),
                              fit: BoxFit.cover,
                              height: previewHeight,
                              width: previewWidth,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: _displaySettingsViewModel.currentTheme.hasAccentColors
                    ? Column(
                        key: const ValueKey('accent'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(top: 14),
                              child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant)
                          ),
                          SizedBox(height: cellHeight),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                S.of(context).accent_color,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Row(
                                spacing: 4,
                                children: availableAccentColors.map((accentColor) {
                                  final isSelected = _displaySettingsViewModel
                                      .isAccentColorSelected(accentColor.name.toLowerCase());
                                  return GestureDetector(
                                    onTap: () {
                                      _displaySettingsViewModel
                                          .onAccentColorSelected(accentColor.name.toLowerCase());
                                    },
                                    child: Stack(
                                      children: [
                                        AnimatedOpacity(
                                          duration: Duration(milliseconds: 350),
                                          opacity: isSelected ? 1 : 0,
                                          child: Container(
                                              width:28,height:28,decoration: BoxDecoration(borderRadius: BorderRadius.circular(99999999),border: Border.all(color:Theme.of(context)
                                              .colorScheme
                                              .onSurface))
                                          ),
                                        ),
                                        AnimatedScale(
                                          duration: Duration(milliseconds: 350),
                                          scale: isSelected ? 0.8 : 1,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(99999999),
                                                color: accentColor.color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no-accent')),
              ),
              if (_displaySettingsViewModel.currentTheme is BlackTheme)
                Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant)
                ),
              if (_displaySettingsViewModel.currentTheme is BlackTheme)
              SettingsSwitcherCell(
                height: 40,
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

  double getHeight(BuildContext context, MaterialThemeBase theme, bool hasAccentColors) {
    final screenHeight = MediaQuery.of(context).size.height;

    double baseHeight = (screenHeight * 0.251).clamp(150.0, screenHeight * 0.5);

    if (hasAccentColors) {
      baseHeight += (screenHeight * 0.6).clamp(35.0, 60.0);
    }

    if (theme is BlackTheme) {
      baseHeight += (screenHeight * 0.057).clamp(48.0, 96.0);
    }

    return baseHeight;
  }

  double _getResponsivePreviewHeight(double screenHeight) =>
      (screenHeight * 0.22).clamp(160.0, 240.0);
}
