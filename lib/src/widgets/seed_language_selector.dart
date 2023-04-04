import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';

class SeedLanguageSelector extends StatefulWidget {
  SeedLanguageSelector({Key? key, required this.initialSelected})
      : super(key: key);

  final String initialSelected;

  @override
  SeedLanguageSelectorState createState() =>
      SeedLanguageSelectorState(selected: initialSelected);
}

class SeedLanguageSelectorState extends State<SeedLanguageSelector> {
  SeedLanguageSelectorState({required this.selected});

  final seedLocales = [
    S.current.seed_language_english,
    S.current.seed_language_chinese,
    S.current.seed_language_dutch,
    S.current.seed_language_german,
    S.current.seed_language_japanese,
    S.current.seed_language_portuguese,
    S.current.seed_language_russian,
    S.current.seed_language_spanish,
    S.current.seed_language_french,
    S.current.seed_language_italian,
  ];
  String selected;

  @override
  Widget build(BuildContext context) {
    return SelectButton(
      image: null,
      text: seedLocales[seedLanguages.indexOf(selected)],
      onTap: () async {
        await showPopUp<String>(
            context: context,
            builder: (_) => SeedLanguagePicker(
                selected: this.selected,
                onItemSelected: (String selected) =>
                    setState(() => this.selected = selected)));
      },
    );
  }
}
