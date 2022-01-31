import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/src/widgets/seed_language_selector.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';

class NewWalletPage extends BasePage {
  NewWalletPage(this._walletNewVM);

  final WalletNewVM _walletNewVM;

  final walletNameImage = Image.asset('assets/images/wallet_name.png');

  final walletNameLightImage =
      Image.asset('assets/images/wallet_name_light.png');

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => WalletNameForm(
      _walletNewVM,
      currentTheme.type == ThemeType.dark
          ? walletNameImage
          : walletNameLightImage);
}

class WalletNameForm extends StatefulWidget {
  WalletNameForm(this._walletNewVM, this.walletImage);

  final WalletNewVM _walletNewVM;
  final Image walletImage;

  @override
  _WalletNameFormState createState() => _WalletNameFormState(_walletNewVM);
}

class _WalletNameFormState extends State<WalletNameForm> {
  _WalletNameFormState(this._walletNewVM);

  static const aspectRatioImage = 1.22;

  final _formKey = GlobalKey<FormState>();
  final _languageSelectorKey = GlobalKey<SeedLanguageSelectorState>();
  ReactionDisposer _stateReaction;
  final WalletNewVM _walletNewVM;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _stateReaction ??=
        reaction((_) => _walletNewVM.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        Navigator.of(context)
            .pushNamed(Routes.preSeed, arguments: _walletNewVM.type);
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (_) {
                return AlertWithOneAction(
                    alertTitle: S.current.new_wallet,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: AspectRatio(
                  aspectRatio: aspectRatioImage,
                  child:
                      FittedBox(child: widget.walletImage, fit: BoxFit.fill)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  onChanged: (value) => _walletNewVM.name = value,
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () async {
                        final rName = await generateName();
                        setState(() {
                          _controller.text = rName;
                          _walletNewVM.name = rName;
                          _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length));
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: Theme.of(context).hintColor,
                        ),
                        width: 34,
                        height: 34,
                        child: Image.asset(
                          'assets/images/refresh_icon.png',
                          color: Theme.of(context)
                              .primaryTextTheme
                              .display1
                              .decorationColor,
                        ),
                      ),
                    ),
                    hintStyle: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).accentTextTheme.display3.color),
                    hintText: S.of(context).wallet_name,
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context)
                                .accentTextTheme
                                .display3
                                .decorationColor,
                            width: 1.0)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .accentTextTheme
                              .display3
                              .decorationColor,
                          width: 1.0),
                    ),
                  ),
                  validator: WalletNameValidator(),
                ),
              ),
            ),
            if (_walletNewVM.hasLanguageSelector) ...[
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  S.of(context).seed_language_choose,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryTextTheme.title.color),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: SeedLanguageSelector(
                    key: _languageSelectorKey,
                    initialSelected: defaultSeedLanguage),
              )
            ]
          ]),
          bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (context) {
              return LoadingPrimaryButton(
                onPressed: _confirmForm,
                text: S.of(context).seed_language_next,
                color: Colors.green,
                textColor: Colors.white,
                isLoading: _walletNewVM.state is IsExecutingState,
                isDisabled: _walletNewVM.name.isEmpty,
              );
            },
          )),
    );
  }

  void _confirmForm() {
    if (!_formKey.currentState.validate()) {
      return;
    }

    _walletNewVM.create(
        options: _walletNewVM.hasLanguageSelector
            ? _languageSelectorKey.currentState.selected
            : null);
  }
}
