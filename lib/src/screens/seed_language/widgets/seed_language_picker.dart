import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:cake_wallet/src/widgets/present_picker.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SeedLanguagePicker extends StatelessWidget {
  List<String> seedLocales = [
    S.current.seed_language_english,
    S.current.seed_language_chinese,
    S.current.seed_language_dutch,
    S.current.seed_language_german,
    S.current.seed_language_japanese,
    S.current.seed_language_portuguese,
    S.current.seed_language_russian,
    S.current.seed_language_spanish
  ];

  @override
  Widget build(BuildContext context) {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    return Observer(
        builder: (_) => InkWell(
          onTap: () => _setSeedLanguage(context),
          child: Container(
            padding: EdgeInsets.all(8.0),
            //width: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).dividerTheme.color
                ),
                borderRadius: BorderRadius.circular(8.0)
            ),
            child: Text(seedLocales[seedLanguages.indexOf(seedLanguageStore.selectedSeedLanguage)],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Palette.lightBlue),
            ),
          ),
        ));
  }

  Future<void> _setSeedLanguage(BuildContext context) async {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);
    String selectedSeedLanguage =
    await presentPicker(context, seedLocales);

    if (selectedSeedLanguage != null) {
      selectedSeedLanguage = seedLanguages[seedLocales.indexOf(selectedSeedLanguage)];
      seedLanguageStore.setSelectedSeedLanguage(selectedSeedLanguage);
    }
  }
}