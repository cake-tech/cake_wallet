import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_keys_form.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_seed_form.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/core/validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/core/seed_validator.dart';

class WalletRestorePage extends BasePage {
  WalletRestorePage(this.walletRestoreViewModel)
      : walletRestoreFromSeedFormKey =
            GlobalKey<WalletRestoreFromSeedFormState>(),
        walletRestoreFromKeysFormKey =
            GlobalKey<WalletRestoreFromKeysFromState>(),
        _pages = [],
        _blockHeightFocusNode = FocusNode(),
        _controller = PageController(initialPage: 0) {
    walletRestoreViewModel.availableModes.forEach((mode) {
      switch (mode) {
        case WalletRestoreMode.seed:
          _pages.add(WalletRestoreFromSeedForm(
              displayBlockHeightSelector:
                  walletRestoreViewModel.hasBlockchainHeightLanguageSelector,
              displayLanguageSelector:
                  walletRestoreViewModel.hasSeedLanguageSelector,
              type: walletRestoreViewModel.type,
              key: walletRestoreFromSeedFormKey,
              blockHeightFocusNode: _blockHeightFocusNode,
              onHeightOrDateEntered: (value) {
                if (_isValidSeed()) {
                  walletRestoreViewModel.isButtonEnabled = value;
                }
              },
              onSeedChange: (String seed) {
                if (walletRestoreViewModel.hasBlockchainHeightLanguageSelector) {
                  final hasHeight = walletRestoreFromSeedFormKey
                      .currentState
                      .blockchainHeightKey
                      .currentState
                      .restoreHeightController
                      .text
                      .isNotEmpty;
                  if (hasHeight) {
                    walletRestoreViewModel.isButtonEnabled = _isValidSeed();
                  }
                } else {
                    walletRestoreViewModel.isButtonEnabled = _isValidSeed();
                }
              },
              onLanguageChange: (_) {
                if (walletRestoreViewModel.hasBlockchainHeightLanguageSelector) {
                  final hasHeight = walletRestoreFromSeedFormKey
                    .currentState
                    .blockchainHeightKey
                    .currentState
                    .restoreHeightController
                    .text
                    .isNotEmpty;

                  if (hasHeight) {
                    walletRestoreViewModel.isButtonEnabled = _isValidSeed(); 
                  }
                } else {
                  walletRestoreViewModel.isButtonEnabled = _isValidSeed();
                }
              }));
          break;
        case WalletRestoreMode.keys:
          _pages.add(WalletRestoreFromKeysFrom(
              key: walletRestoreFromKeysFormKey,
              onHeightOrDateEntered: (value) =>
                  walletRestoreViewModel.isButtonEnabled = value));
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget middle(BuildContext context) => Observer(
      builder: (_) => Text(
            walletRestoreViewModel.mode == WalletRestoreMode.seed
                ? S.current.restore_title_from_seed
                : S.current.restore_title_from_keys,
            style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
                color: titleColor ??
                    Theme.of(context).primaryTextTheme.title.color),
          ));

  final WalletRestoreViewModel walletRestoreViewModel;
  final PageController _controller;
  final List<Widget> _pages;
  final GlobalKey<WalletRestoreFromSeedFormState> walletRestoreFromSeedFormKey;
  final GlobalKey<WalletRestoreFromKeysFromState> walletRestoreFromKeysFormKey;
  final FocusNode _blockHeightFocusNode;

  @override
  Widget body(BuildContext context) {
    reaction((_) => walletRestoreViewModel.state, (ExecutionState state) {
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

    reaction((_) => walletRestoreViewModel.mode, (WalletRestoreMode mode) {
      walletRestoreViewModel.isButtonEnabled = false;

      walletRestoreFromSeedFormKey.currentState.blockchainHeightKey.currentState
          .restoreHeightController.text = '';
      walletRestoreFromSeedFormKey.currentState.blockchainHeightKey.currentState
          .dateController.text = '';
      walletRestoreFromSeedFormKey.currentState.nameTextEditingController.text = '';

      walletRestoreFromKeysFormKey.currentState.blockchainHeightKey.currentState
          .restoreHeightController.text = '';
      walletRestoreFromKeysFormKey.currentState.blockchainHeightKey.currentState
          .dateController.text = '';
      walletRestoreFromKeysFormKey.currentState.nameTextEditingController.text = '';
    });

    return KeyboardActions(
    config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).accentTextTheme.body2
                .backgroundColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _blockHeightFocusNode,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              )
            ]),
    child: Container(
          height: 0,
          color: Theme.of(context).backgroundColor,
	  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
          child: PageView.builder(
              onPageChanged: (page) {
                walletRestoreViewModel.mode =
                    page == 0 ? WalletRestoreMode.seed : WalletRestoreMode.keys;
              },
              controller: _controller,
              itemCount: _pages.length,
              itemBuilder: (_, index) =>
                  SingleChildScrollView(child: _pages[index]))),
      if (_pages.length > 1)
        Padding(
            padding: EdgeInsets.only(top: 10),
            child: SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ColorTransitionEffect(
                  spacing: 6.0,
                  radius: 6.0,
                  dotWidth: 6.0,
                  dotHeight: 6.0,
                  dotColor: Theme.of(context).hintColor.withOpacity(0.5),
                  activeDotColor: Theme.of(context).hintColor),
            )),
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 24, left: 24, right: 24),
          child: Observer(
            builder: (context) {
              return LoadingPrimaryButton(
                onPressed: () =>
                    walletRestoreViewModel.create(options: _credentials()),
                text: S.of(context).restore_recover,
                color:
                    Theme.of(context).accentTextTheme.subtitle.decorationColor,
                textColor:
                    Theme.of(context).accentTextTheme.headline.decorationColor,
                isLoading: walletRestoreViewModel.state is IsExecutingState,
                isDisabled: !walletRestoreViewModel.isButtonEnabled,
              );
            },
          ))
    ])));
  }

  bool _isValidSeed() {
    final seedWords = walletRestoreFromSeedFormKey
      .currentState
      .seedWidgetStateKey
      .currentState
      .text
      .split(' ');

    if ((walletRestoreViewModel.type == WalletType.monero || walletRestoreViewModel.type == WalletType.haven) &&
        seedWords.length != WalletRestoreViewModelBase.moneroSeedMnemonicLength) {
      return false;
    }
    
    if ((walletRestoreViewModel.type == WalletType.bitcoin ||
        walletRestoreViewModel.type == WalletType.litecoin) && 
      (seedWords.length != WalletRestoreViewModelBase.electrumSeedMnemonicLength &&
        seedWords.length != WalletRestoreViewModelBase.electrumShortSeedMnemonicLength)) {
      return false;
    }

    final words = walletRestoreFromSeedFormKey
      .currentState
      .seedWidgetStateKey
      .currentState
      .words
      .toSet();
    return seedWords
      .toSet()
      .difference(words)
      .toSet()
      .isEmpty;
  }

  Map<String, dynamic> _credentials() {
    final credentials = <String, dynamic>{};

    if (walletRestoreViewModel.mode == WalletRestoreMode.seed) {
      credentials['seed'] = walletRestoreFromSeedFormKey
          .currentState.seedWidgetStateKey.currentState.text;

      if (walletRestoreViewModel.hasBlockchainHeightLanguageSelector) {
        credentials['height'] = walletRestoreFromSeedFormKey
            .currentState.blockchainHeightKey.currentState.height;
      }

      credentials['name'] = walletRestoreFromSeedFormKey.currentState.nameTextEditingController.text;
    } else {
      credentials['address'] =
          walletRestoreFromKeysFormKey.currentState.addressController.text;
      credentials['viewKey'] =
          walletRestoreFromKeysFormKey.currentState.viewKeyController.text;
      credentials['spendKey'] =
          walletRestoreFromKeysFormKey.currentState.spendKeyController.text;
      credentials['height'] = walletRestoreFromKeysFormKey
          .currentState.blockchainHeightKey.currentState.height;
      credentials['name'] = walletRestoreFromKeysFormKey.currentState.nameTextEditingController.text;
    }

    return credentials;
  }
}
