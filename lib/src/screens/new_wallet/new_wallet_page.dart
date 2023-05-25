import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
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

  final walletNameLightImage = Image.asset('assets/images/wallet_name_light.png');

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => WalletNameForm(
      _walletNewVM, currentTheme.type == ThemeType.dark ? walletNameImage : walletNameLightImage);
}

class WalletNameForm extends StatefulWidget {
  WalletNameForm(this._walletNewVM, this.walletImage);

  final WalletNewVM _walletNewVM;
  final Image walletImage;

  @override
  _WalletNameFormState createState() => _WalletNameFormState(_walletNewVM);
}

class _WalletNameFormState extends State<WalletNameForm> {
  _WalletNameFormState(this._walletNewVM)
      : _formKey = GlobalKey<FormState>(),
        _languageSelectorKey = GlobalKey<SeedLanguageSelectorState>(),
        _controller = TextEditingController();

  static const aspectRatioImage = 1.22;

  final GlobalKey<FormState> _formKey;
  final GlobalKey<SeedLanguageSelectorState> _languageSelectorKey;
  final WalletNewVM _walletNewVM;
  final TextEditingController _controller;
  ReactionDisposer? _stateReaction;

  @override
  void initState() {
    _stateReaction ??= reaction((_) => _walletNewVM.state, (ExecutionState state) async {
      if (state is ExecutedSuccessfullyState) {
        Navigator.of(navigatorKey.currentContext!)
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
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: ResponsiveLayoutUtil.kDesktopMaxWidthConstraint),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12, right: 12),
                    child: AspectRatio(
                        aspectRatio: aspectRatioImage,
                        child: FittedBox(child: widget.walletImage, fit: BoxFit.fill)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Form(
                      key: _formKey,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextFormField(
                            onChanged: (value) => _walletNewVM.name = value,
                            controller: _controller,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .primaryTextTheme!
                                    .titleLarge!
                                    .color!),
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .accentTextTheme!
                                      .displayMedium!
                                      .color),
                              hintText: S.of(context).wallet_name,
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .accentTextTheme!
                                          .displayMedium!
                                          .decorationColor!,
                                      width: 1.0)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .accentTextTheme!
                                        .displayMedium!
                                        .decorationColor!,
                                    width: 1.0),
                              ),
                              suffixIcon: Semantics(
                                label: 'Generate Name',
                                child: IconButton(
                                  onPressed: () async {
                                    final rName = await generateName();
                                    FocusManager.instance.primaryFocus?.unfocus();

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
                                          .primaryTextTheme!
                                          .headlineMedium!
                                          .decorationColor!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            validator: WalletNameValidator(),
                          ),
                        ],
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
                            color: Theme.of(context)
                                .primaryTextTheme!
                                .titleLarge!
                                .color!),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: SeedLanguageSelector(
                          key: _languageSelectorKey, initialSelected: defaultSeedLanguage),
                    )
                  ]
                ],
              ),
            ),
          ),
          bottomSectionPadding: EdgeInsets.all(24),
          bottomSection: Column(
            children: [
              Observer(
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
              ),
              const SizedBox(height: 25),
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(Routes.advancedPrivacySettings, arguments: _walletNewVM.type);
                },
                child: Text(S.of(context).advanced_privacy_settings),
              ),
            ],
          )),
    );
  }

  void _confirmForm() {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    if (_walletNewVM.nameExists(_walletNewVM.name)) {
      showPopUp<void>(
          context: context,
          builder: (_) {
            return AlertWithOneAction(
                alertTitle: '',
                alertContent: S.of(context).wallet_name_exists,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    } else {
      _walletNewVM.create(
          options: _walletNewVM.hasLanguageSelector
              ? _languageSelectorKey.currentState!.selected
              : null);
    }
  }
}
