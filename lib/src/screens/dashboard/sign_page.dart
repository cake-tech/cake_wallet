import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sign_form.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/verify_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';

import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/sign_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SignPage extends BasePage {
  SignPage(this.signViewModel)
      : signFormKey = GlobalKey<SignFormState>(),
        verifyFormKey = GlobalKey<VerifyFormState>(),
        _pages = [],
        _controller = PageController(initialPage: 0) {
    _pages.add(SignForm(
      key: signFormKey,
      type: signViewModel.wallet.type,
      chainId: signViewModel.wallet.chainId,
      includeAddress: signViewModel.signIncludesAddress,
    ));
    _pages.add(VerifyForm(
      key: verifyFormKey,
      type: signViewModel.wallet.type,
      chainId: signViewModel.wallet.chainId,
    ));
  }

  @override
  Widget middle(BuildContext context) => Observer(
        builder: (_) {
          return Text(
            S.current.sign_verify_title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
          );
        },
      );

  final SignViewModel signViewModel;
  final PageController _controller;
  final List<Widget> _pages;
  final GlobalKey<SignFormState> signFormKey;
  final GlobalKey<VerifyFormState> verifyFormKey;
  bool _isEffectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Theme.of(context).colorScheme.surfaceVariant,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: FocusNode(),
            toolbarButtons: [(_) => KeyboardDoneButton()],
          )
        ],
      ),
      child: Container(
        height: 0,
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PageView.builder(
                  onPageChanged: (page) {
                    signViewModel.isSigning = page == 0;
                  },
                  controller: _controller,
                  itemCount: _pages.length,
                  itemBuilder: (_, index) => SingleChildScrollView(child: _pages[index]),
                ),
              ),
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
                      dotColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      activeDotColor: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 20, bottom: 24, left: 24, right: 24),
                child: Column(
                  children: [
                    Observer(
                      builder: (context) {
                        return LoadingPrimaryButton(
                          onPressed: () async {
                            await _confirmForm(context);
                          },
                          text: signViewModel.isSigning
                              ? S.current.sign_message
                              : S.current.verify_message,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          isLoading: signViewModel.state is IsExecutingState,
                          isDisabled: signViewModel.state is IsExecutingState,
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _setEffects(BuildContext context) async {
    if (_isEffectsInstalled) {
      return;
    }
    _isEffectsInstalled = true;

    reaction((_) => signViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (_) {
                return AlertWithOneAction(
                  alertTitle: S.current.error,
                  alertContent: state.error,
                  buttonText: S.of(context).ok,
                  buttonAction: () {
                    if (Navigator.canPop(context)) Navigator.of(context).pop();
                  },
                );
              });
        });
      }
      if (state is ExecutedSuccessfullyState) {
        if (signViewModel.isSigning) {
          signFormKey.currentState!.signatureController.text = state.payload as String;
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showPopUp<void>(
                context: context,
                builder: (_context) {
                  return AlertWithOneAction(
                    alertTitle: S.current.successful,
                    alertContent: S.current.message_verified,
                    buttonText: S.of(_context).ok,
                    buttonAction: () {
                      if (_context.mounted) Navigator.of(_context).pop();
                    },
                  );
                });
          });
        }
      }
    });
  }

  Future<void> _confirmForm(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (signViewModel.isSigning) {
      String message = signFormKey.currentState!.messageController.text;
      String? address;
      if (signViewModel.signIncludesAddress) {
        address = signFormKey.currentState!.addressController.text;
      }
      await signViewModel.sign(message, address: address);
    } else {
      String message = verifyFormKey.currentState!.messageController.text;
      String signature = verifyFormKey.currentState!.signatureController.text;
      String address = verifyFormKey.currentState!.addressController.text;
      await signViewModel.verify(message, signature, address: address);
    }
  }
}
