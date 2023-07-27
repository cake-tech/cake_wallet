import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

List<Image> flagImages = [
  Image.asset('assets/images/flags/usa.png'),
  Image.asset('assets/images/flags/chn.png'),
  Image.asset('assets/images/flags/nld.png'),
  Image.asset('assets/images/flags/deu.png'),
  Image.asset('assets/images/flags/jpn.png'),
  Image.asset('assets/images/flags/prt.png'),
  Image.asset('assets/images/flags/rus.png'),
  Image.asset('assets/images/flags/esp.png'),
  Image.asset('assets/images/flags/fra.png'),
  Image.asset('assets/images/flags/ita.png'),
];

const List<String> languageCodes = [
  'Eng',
  'Chi',
  'Ned',
  'Ger',
  'Jap',
  'Por',
  'Rus',
  'Esp',
  'Fre',
  'Ita',
];

const defaultSeedLanguage = 'English';

const List<String> seedLanguages = [
  defaultSeedLanguage,
  'Chinese (simplified)',
  'Dutch',
  'German',
  'Japanese',
  'Portuguese',
  'Russian',
  'Spanish',
  'French',
  'Italian',
];

enum Places { topLeft, topRight, bottomLeft, bottomRight, inside }

class SeedLanguagePicker extends StatefulWidget {
  SeedLanguagePicker({Key? key, this.selected = defaultSeedLanguage, required this.onItemSelected})
      : super(key: key);

  final String selected;
  final Function(String) onItemSelected;

  @override
  SeedLanguagePickerState createState() =>
      SeedLanguagePickerState(selected: selected, onItemSelected: onItemSelected);
}

class SeedLanguagePickerState extends State<SeedLanguagePicker> {
  SeedLanguagePickerState({required this.selected, required this.onItemSelected});

  final String selected;
  final Function(String) onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Picker(
      selectedAtIndex: seedLanguages.indexOf(selected),
      items: seedLanguages,
      images: flagImages,
      isGridView: true,
      title: S.of(context).seed_choose,
      hintText: S.of(context).seed_choose,
      matchingCriteria: (String language, String searchText) {
        return language.toLowerCase().contains(searchText);
      },
      onItemSelected: onItemSelected,
    );
  }
}
