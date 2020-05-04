import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet_creation/wallet_creation_store.dart';
import 'package:cake_wallet/src/stores/wallet_creation/wallet_creation_state.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

class NewWalletPage extends BasePage {
  NewWalletPage(
      {@required this.walletsService,
      @required this.walletService,
      @required this.sharedPreferences});

  final WalletListService walletsService;
  final WalletService walletService;
  final SharedPreferences sharedPreferences;

  @override
  String get title => S.current.new_wallet;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => WalletNameForm();
}

class WalletNameForm extends StatefulWidget {
  @override
  _WalletNameFormState createState() => _WalletNameFormState();
}

class _WalletNameFormState extends State<WalletNameForm> {
  static const aspectRatioImage = 1.22;

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final walletNameImage = Image.asset('assets/images/wallet_name.png');

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletCreationStore = Provider.of<WalletCreationStore>(context);
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    final List<String> seedLocales = [
      S.current.seed_language_english,
      S.current.seed_language_chinese,
      S.current.seed_language_dutch,
      S.current.seed_language_german,
      S.current.seed_language_japanese,
      S.current.seed_language_portuguese,
      S.current.seed_language_russian,
      S.current.seed_language_spanish
    ];

    nameController.addListener(() {
      if (nameController.text.isNotEmpty) {
        walletCreationStore.setDisabledStatus(false);
      } else {
        walletCreationStore.setDisabledStatus(true);
      }
    });

    reaction((_) => walletCreationStore.state, (WalletCreationState state) {
      if (state is WalletCreatedSuccessfully) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (state is WalletCreationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (_) {
                return AlertWithOneAction(
                    alertTitle: S.current.new_wallet,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                );
              });
        });
      }
    });

    return Container(
      color: PaletteDark.historyPanel,
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12, right: 12),
                child: AspectRatio(
                    aspectRatio: aspectRatioImage,
                    child: FittedBox(child: walletNameImage, fit: BoxFit.fill)),
              ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Form(
                  key: _formKey,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    controller: nameController,
                    decoration: InputDecoration(
                        hintStyle: TextStyle(
                            fontSize: 16.0,
                            color: PaletteDark.walletCardText),
                        hintText: S.of(context).wallet_name,
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                            BorderSide(
                                color: PaletteDark.walletCardSubAddressField,
                                width: 1.0)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: PaletteDark.walletCardSubAddressField,
                                width: 1.0))),
                    validator: (value) {
                      walletCreationStore.validateWalletName(value);
                      return walletCreationStore.errorMessage;
                    },
                  )),
            ),
            Padding(padding: EdgeInsets.only(top: 40),
              child: Text(
                S.of(context).seed_language_choose,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white
                ),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 24),
              child: Observer(
                builder: (_) => SelectButton(
                  image: null,
                  text: seedLocales[seedLanguages.indexOf(seedLanguageStore.selectedSeedLanguage)],
                  color: PaletteDark.menuList,
                  textColor: Colors.white,
                  onTap: () async => await showDialog(
                    context: context,
                    builder: (BuildContext context) => SeedLanguagePicker()
                  )
                )
              ),
            )
          ]),
          bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (context) {
              return LoadingPrimaryButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    walletCreationStore.create(name: nameController.text,
                        language: seedLanguageStore.selectedSeedLanguage);
                  }
                },
                text: S.of(context).continue_text,
                color: Colors.green,
                textColor: Colors.white,
                isLoading: walletCreationStore.state is WalletIsCreating,
                isDisabled: walletCreationStore.isDisabledStatus,
              );
            },
          )),
    );
  }
}
