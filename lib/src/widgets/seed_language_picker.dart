import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

import 'package:cake_wallet/entities/seed_type.dart';

class SeedLanguagePickerOption {
  SeedLanguagePickerOption(this.name, this.nameLocalized, this.image, this.supportedSeedTypes);

  final String name;
  final String nameLocalized;
  final Image image;
  final List<SeedType> supportedSeedTypes;
}

final List<SeedLanguagePickerOption> seedLanguages = [
  SeedLanguagePickerOption('English', S.current.seed_language_english,
      Image.asset('assets/images/flags/usa.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('Chinese (simplified)', S.current.seed_language_chinese,
      Image.asset('assets/images/flags/chn.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('Chinese (Traditional)', S.current.seed_language_chinese_traditional,
      Image.asset('assets/images/flags/chn.png'), [SeedType.polyseed]),
  SeedLanguagePickerOption('Dutch', S.current.seed_language_dutch,
      Image.asset('assets/images/flags/nld.png'), [SeedType.legacy]),
  SeedLanguagePickerOption('German', S.current.seed_language_german,
      Image.asset('assets/images/flags/deu.png'), [SeedType.legacy]),
  SeedLanguagePickerOption('Japanese', S.current.seed_language_japanese,
      Image.asset('assets/images/flags/jpn.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('Korean', S.current.seed_language_korean,
      Image.asset('assets/images/flags/kor.png'), [SeedType.polyseed]),
  SeedLanguagePickerOption('Portuguese', S.current.seed_language_portuguese,
      Image.asset('assets/images/flags/prt.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('Russian', S.current.seed_language_russian,
      Image.asset('assets/images/flags/rus.png'), [SeedType.legacy]),
  SeedLanguagePickerOption('Czech', S.current.seed_language_czech,
      Image.asset('assets/images/flags/czk.png'), [SeedType.polyseed]),
  SeedLanguagePickerOption('Spanish', S.current.seed_language_spanish,
      Image.asset('assets/images/flags/esp.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('French', S.current.seed_language_french,
      Image.asset('assets/images/flags/fra.png'), [SeedType.legacy, SeedType.polyseed]),
  SeedLanguagePickerOption('Italian', S.current.seed_language_italian,
      Image.asset('assets/images/flags/ita.png'), [SeedType.legacy, SeedType.polyseed]),
];

const defaultSeedLanguage = 'English';

enum Places { topLeft, topRight, bottomLeft, bottomRight, inside }

class SeedLanguagePicker extends StatefulWidget {
  SeedLanguagePicker(
      {Key? key,
      this.selected = defaultSeedLanguage,
      this.seedType = SeedType.defaultSeedType,
      required this.onItemSelected})
      : super(key: key);

  final SeedType seedType;
  final String selected;
  final Function(String) onItemSelected;

  @override
  SeedLanguagePickerState createState() => SeedLanguagePickerState(
      selected: selected, onItemSelected: onItemSelected, seedType: seedType);
}

class SeedLanguagePickerState extends State<SeedLanguagePicker> {
  SeedLanguagePickerState(
      {required this.selected, required this.onItemSelected, required this.seedType});

  final SeedType seedType;
  final String selected;
  final Function(String) onItemSelected;

  @override
  Widget build(BuildContext context) {
    final availableSeedLanguages = seedLanguages
        .where((SeedLanguagePickerOption e) => e.supportedSeedTypes.contains(seedType));

    return Picker(
      selectedAtIndex: availableSeedLanguages.map((e) => e.name).toList().indexOf(selected),
      items: availableSeedLanguages.map((e) => e.name).toList(),
      images: availableSeedLanguages.map((e) => e.image).toList(),
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
