import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

class SeedLanguageSelector extends StatefulWidget {
  SeedLanguageSelector(
      {Key? key, required this.initialSelected, this.seedType = SeedType.defaultSeedType})
      : super(key: key);

  final String initialSelected;
  final SeedType seedType;

  @override
  SeedLanguageSelectorState createState() => SeedLanguageSelectorState(selected: initialSelected);
}

class SeedLanguageSelectorState extends State<SeedLanguageSelector> {
  SeedLanguageSelectorState({required this.selected});

  String selected;

  @override
  Widget build(BuildContext context) {
    return SelectButton(
      image: null,
      text:
          "${seedLanguages.firstWhere((e) => e.name == selected).nameLocalized} (${S.of(context).seed_language})",
      onTap: () async {
        await showPopUp<String>(
          context: context,
          builder: (_) => SeedLanguagePicker(
            selected: this.selected,
            seedType: widget.seedType,
            onItemSelected: (String selected) => setState(() => this.selected = selected),
          ),
        );
      },
    );
  }
}
