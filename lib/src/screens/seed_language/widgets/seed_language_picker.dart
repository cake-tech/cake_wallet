import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

List<Image> flagImages = [
  Image.asset('assets/images/usa.png'),
  Image.asset('assets/images/china.png'),
  Image.asset('assets/images/holland.png'),
  Image.asset('assets/images/germany.png'),
  Image.asset('assets/images/japan.png'),
  Image.asset('assets/images/portugal.png'),
  Image.asset('assets/images/russia.png'),
  Image.asset('assets/images/spain.png'),
  Image.asset('assets/images/france.png'),
  Image.asset('assets/images/italy.png'),
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
