import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';

class WalletRestoreFromSeedForm extends StatefulWidget {
  WalletRestoreFromSeedForm({Key key, this.blockHeightFocusNode,
    this.onHeightOrDateEntered})
      : super(key: key);

  final FocusNode blockHeightFocusNode;
  final Function (bool) onHeightOrDateEntered;

  @override
  WalletRestoreFromSeedFormState createState() =>
      WalletRestoreFromSeedFormState('English');
}

class WalletRestoreFromSeedFormState extends State<WalletRestoreFromSeedForm> {
  WalletRestoreFromSeedFormState(this.language)
      : seedWidgetStateKey = GlobalKey<SeedWidgetState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        languageController = TextEditingController();

  final GlobalKey<SeedWidgetState> seedWidgetStateKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController languageController;
  String language;

  @override
  void initState() {
    _setLanguageLabel(language);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 25, right: 25),
        child: Column(children: [
          SeedWidget(key: seedWidgetStateKey, language: language),
          GestureDetector(
              onTap: () async {
                final selected = await showPopUp<String>(
                    context: context,
                    builder: (BuildContext context) =>
                        SeedLanguagePicker(selected: language));

                if (selected == null || selected.isEmpty) {
                  return;
                }

                _changeLanguage(selected);
              },
              child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(top: 20.0),
                  child: IgnorePointer(
                      child: BaseTextFormField(
                          controller: languageController,
                          enableInteractiveSelection: false,
                          readOnly: true)))),
          BlockchainHeightWidget(
              focusNode: widget.blockHeightFocusNode,
              key: blockchainHeightKey,
              onHeightOrDateEntered: widget.onHeightOrDateEntered)
        ]));
  }

  void _changeLanguage(String language) {
    setState(() {
      this.language = language;
      seedWidgetStateKey.currentState.changeSeedLanguage(language);
      _setLanguageLabel(language);
    });
  }

  void _setLanguageLabel(String language) =>
      languageController.text = '$language (Seed language)';
}
