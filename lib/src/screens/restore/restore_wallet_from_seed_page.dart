import 'package:cake_wallet/src/screens/restore/restore_from_keys.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/seed_widget.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/core/mnemonic_length.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RestoreWalletFromSeedPage extends BasePage {
  RestoreWalletFromSeedPage({@required this.type});

  final WalletType type;
  final String language = 'en';

  // final formKey = GlobalKey<_RestoreFromSeedFormState>();
  // final formKey = GlobalKey<_RestoreFromSeedFormState>();

  @override
  String get title => S.current.restore_title_from_seed;

  final controller = PageController(initialPage: 0);

  Widget _page(BuildContext context, int index) {
    if (_pages == null || _pages.isEmpty) {
      _setPages(context);
    }

    return _pages[index];
  }

  int _pageLength(BuildContext context) {
    if (_pages == null || _pages.isEmpty) {
      _setPages(context);
    }

    return _pages.length;
  }

  void _setPages(BuildContext context) {
    _pages = <Widget>[
      Container(
          padding: EdgeInsets.only(left: 25, right: 25),
          child: Column(children: [
            SeedWidget(
              maxLength: mnemonicLength(WalletType.monero),
              onMnemonicChange: (seed) => null,
              onFinish: () => null,
              // Navigator.of(context).pushNamed(
              // Routes.restoreWalletFromSeedDetails,
              // arguments: [WalletType.monero, '', '']),
              validator: SeedValidator(type: WalletType.monero, language: ''),
            ),
            GestureDetector(
                onTap: () async {
                  final selected = await showPopUp<String>(
                      context: context,
                      builder: (BuildContext context) =>
                          SeedLanguagePicker(selected: 'English')); //key: _pickerKey
                  print('Seletec $selected');
                },
                child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(top: 20.0),
                    child: IgnorePointer(child: BaseTextFormField(
                        enableInteractiveSelection: false,
                        readOnly: true,
                        hintText: 'Language',
                        initialValue: 'English (Seed language)')))),
            BlockchainHeightWidget(
                // key: _blockchainHeightKey,
                onHeightChange: (height) {
              // widget.walletRestorationFromKeysVM.height = height;
              print(height);
            })
          ])),
      RestoreFromKeysFrom(),
      // Container(color: Colors.yellow)
    ];
  }

  List<Widget> _pages;

  @override
  Widget body(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
          child: PageView.builder(
              onPageChanged: (page) {
                print('Page index $page');
              },
              controller: controller,
              itemCount: _pageLength(context),
              itemBuilder: (context, index) => _page(context, index))),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: SmoothPageIndicator(
            controller: controller,
            count: _pageLength(context),
            effect: ColorTransitionEffect(
                spacing: 6.0,
                radius: 6.0,
                dotWidth: 6.0,
                dotHeight: 6.0,
                dotColor: Theme.of(context).hintColor.withOpacity(0.5),
                activeDotColor: Theme.of(context).hintColor),
          )),
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 40, left: 25, right: 25),
          child: PrimaryButton(
              text: S.of(context).restore_recover,
              isDisabled: false,
              onPressed: () => null,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white)),
    ]);

    // return GestureDetector(
    //   onTap: () =>
    //       SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
    //   child: ScrollableWithBottomSection(
    //       bottomSection: Column(children: [
    //         GestureDetector(
    //             onTap: () {},
    //             child: Text('Switch to restore from keys',
    //                 style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor))),
    //         SizedBox(height: 30),
    //         PrimaryButton(
    //             text: S.of(context).restore_next,
    //             isDisabled: false,
    //             onPressed: () => null,
    //             color: Theme.of(context).accentTextTheme.body2.color,
    //             textColor: Colors.white)
    //       ]),
    //       contentPadding: EdgeInsets.only(bottom: 24),
    //       content: Container(
    //           padding: EdgeInsets.only(left: 25, right: 25),
    //           child: Column(children: [
    //             SeedWidget(
    //               maxLength: mnemonicLength(type),
    //               onMnemonicChange: (seed) => null,
    //               onFinish: () => Navigator.of(context).pushNamed(
    //                   Routes.restoreWalletFromSeedDetails,
    //                   arguments: [type, language, '']),
    //               validator: SeedValidator(type: type, language: language),
    //             ),
    //             // SizedBox(height: 15),
    //             // BaseTextFormField(hintText: 'Language', initialValue: 'English'),
    //             BlockchainHeightWidget(
    //                 // key: _blockchainHeightKey,
    //                 onHeightChange: (height) {
    //               // widget.walletRestorationFromKeysVM.height = height;
    //               print(height);
    //             })
    //           ]))),
    // );
  }
}

class RestoreFromSeedForm extends StatefulWidget {
  RestoreFromSeedForm(
      {Key key, this.type, this.language, this.leading, this.middle})
      : super(key: key);
  final WalletType type;
  final String language;
  final Widget leading;
  final Widget middle;

  @override
  _RestoreFromSeedFormState createState() => _RestoreFromSeedFormState();
}

class _RestoreFromSeedFormState extends State<RestoreFromSeedForm> {
  // final _seedKey = GlobalKey<SeedWidgetState>();

  String mnemonic() =>
      ''; // _seedKey.currentState.items.map((e) => e.text).join(' ');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide'),
      child: Container(
          padding: EdgeInsets.only(left: 25, right: 25),
          // color: Colors.blue,
          // height: 300,
          child: Column(children: [
            SeedWidget(
              // key: _seedKey,
              maxLength: mnemonicLength(widget.type),
              onMnemonicChange: (seed) => null,
              onFinish: () => Navigator.of(context).pushNamed(
                  Routes.restoreWalletFromSeedDetails,
                  arguments: [widget.type, widget.language, mnemonic()]),
              leading: widget.leading,
              middle: widget.middle,
              validator:
                  SeedValidator(type: widget.type, language: widget.language),
            ),
            BlockchainHeightWidget(
                // key: _blockchainHeightKey,
                onHeightChange: (height) {
              // widget.walletRestorationFromKeysVM.height = height;
              print(height);
            }),
            Container(
                color: Colors.green,
                width: 100,
                height: 56,
                child: BaseTextFormField(
                    hintText: 'Language', initialValue: 'English')),
          ])),
    );
  }
}
