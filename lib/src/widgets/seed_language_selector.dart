import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

class SeedLanguageSelector extends StatefulWidget {
  SeedLanguageSelector({
    required this.initialSelected,
    this.seedType = MoneroSeedType.defaultSeedType,
    this.buttonKey,
    this.borderRadius,
    required this.currentTheme,
    Key? key,
  }) : super(key: key);

  final String initialSelected;
  final MoneroSeedType seedType;
  final Key? buttonKey;
  final BorderRadius? borderRadius;
  final MaterialThemeBase currentTheme;
  
  @override
  SeedLanguageSelectorState createState() => SeedLanguageSelectorState(selected: initialSelected);
}

class SeedLanguageSelectorState extends State<SeedLanguageSelector> {
  SeedLanguageSelectorState({required this.selected});

  String selected;

  @override
  Widget build(BuildContext context) {
    return SelectButton(
      borderRadius: widget.borderRadius,
      key: widget.buttonKey,
      image: null,
      text:
          "${seedLanguages.firstWhere((e) => e.name == selected).nameLocalized} (${S.of(context).seed_language})",
      onTap: () async {
        await showPopUp<String>(
          context: context,
          builder: (_) => SeedLanguagePicker(
            currentTheme: widget.currentTheme,
            selected: this.selected,
            seedType: widget.seedType,
            onItemSelected: (String selected) => setState(() => this.selected = selected),
          ),
        );
      },
    );
  }
}
