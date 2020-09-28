import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';

class SeedLanguageSelector extends StatefulWidget {
  SeedLanguageSelector({Key key, this.initialSelected}) : super(key: key);

  final String initialSelected;

  @override
  SeedLanguageSelectorState createState() =>
      SeedLanguageSelectorState(selected: initialSelected);
}

class SeedLanguageSelectorState extends State<SeedLanguageSelector> {
  SeedLanguageSelectorState({this.selected});

  final seedLocales = [
    S.current.seed_language_english,
    S.current.seed_language_chinese,
    S.current.seed_language_dutch,
    S.current.seed_language_german,
    S.current.seed_language_japanese,
    S.current.seed_language_portuguese,
    S.current.seed_language_russian,
    S.current.seed_language_spanish
  ];
  String selected;
  final _pickerKey = GlobalKey<SeedLanguagePickerState>();

  @override
  Widget build(BuildContext context) {
    return SelectButton(
        image: null,
        text: seedLocales[seedLanguages.indexOf(selected)],
        onTap: () async {
          final selected = await showPopUp<String>(
              context: context,
              builder: (BuildContext context) =>
                  SeedLanguagePicker(key: _pickerKey, selected: this.selected));
          if (selected != null) {
            setState(() => this.selected = selected);
          }
        });
  }
}
