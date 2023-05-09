import 'package:another_flushbar/flushbar.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:flutter/material.dart';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:mobx/mobx.dart';

import '../../../palette.dart';
import '../../widgets/auth_options_base.dart';

typedef OnTotpAuthenticationFinished = void Function(bool, TotpAuthCodePageState);

class TotpAuthCodePage extends AuthOptions {
  TotpAuthCodePage(
    this.setup2FAViewModel, {
    required this.onAuthenticationFinished,
    required this.configParams,
  });

  final Setup2FAViewModel setup2FAViewModel;
  final OnTotpAuthenticationFinished onAuthenticationFinished;
  final List<bool?> configParams;

  @override
  TotpAuthCodePageState createState() => TotpAuthCodePageState();
}

class TotpAuthCodePageState extends State<TotpAuthCodePage> {
  final _key = GlobalKey<ScaffoldState>();

  ReactionDisposer? _reaction;
  Flushbar<void>? _authBar;
  Flushbar<void>? _progressBar;

  @override
  void initState() {
    _reaction ??= reaction((_) => widget.setup2FAViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          widget.onAuthenticationFinished(true, this);
        });
        setState(() {});
      }

      if (state is IsExecutingState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {});
      }

      if (state is FailureState) {
        print(state.error);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          widget.onAuthenticationFinished(false, this);
        });
        setState(() {});
      }

      if (state is AuthenticationBanned) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          widget.onAuthenticationFinished(false, this);
        });
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _reaction?.reaction.dispose();
    super.dispose();
  }

  void changeProcessText(String text) {
    dismissFlushBar(_authBar);
    _progressBar = createBar<void>(text, duration: null)..show(_key.currentContext!);
  }

  Future<void> close({String? route, dynamic arguments}) async {
    if (_key.currentContext == null) {
      throw Exception('Key context is null. Should be not happened');
    }
    await Future<void>.delayed(Duration(milliseconds: 50));
    if (route != null) {
      Navigator.of(_key.currentContext!).pushReplacementNamed(route, arguments: arguments);
    } else {
      Navigator.of(_key.currentContext!).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      resizeToAvoidBottomInset: false,
      body: TOTPEnterCode(
        setup2FAViewModel: widget.setup2FAViewModel,
        isForSetup: widget.configParams[0] ?? false,
        closable: widget.configParams[1] ?? true,
      ),
    );
  }

  void dismissFlushBar(Flushbar<dynamic>? bar) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await bar?.dismiss();
    });
  }
}

class TOTPEnterCode extends BasePage {
  TOTPEnterCode({
    required this.setup2FAViewModel,
    required this.isForSetup,
    required this.closable,
  }) : totpController = TextEditingController();

  @override
  String get title => isForSetup ? S.current.setup_2fa : S.current.verify_with_2fa;

  Widget? leading(BuildContext context) {
    return closable ? super.leading(context) : null;
  }

  final TextEditingController totpController;
  final Setup2FAViewModel setup2FAViewModel;
  final bool isForSetup;
  final bool closable;

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        children: [
          BaseTextFormField(
            textAlign: TextAlign.left,
            hintText: S.current.totp_code,
            controller: totpController,
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            placeholderTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text(
            S.current.please_fill_totp,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: Palette.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          PrimaryButton(
            onPressed: () async {
              final result = await setup2FAViewModel.totp2FAAuth(totpController.text, isForSetup);
              final bannedState = setup2FAViewModel.state is AuthenticationBanned;

              await showPopUp<void>(
                context: context,
                builder: (BuildContext context) {
                  return PopUpCancellableAlertDialog(
                    contentText: () {
                      switch (result) {
                        case true:
                          return isForSetup
                              ? S.current.totp_2fa_success
                              : S.current.totp_verification_success;
                        case false:
                          if (bannedState) {
                            final state = setup2FAViewModel.state as AuthenticationBanned;
                            return S.of(context).failed_authentication(state.error);
                          } else {
                            return S.current.totp_2fa_failure;
                          }
                        default:
                          return S.current.enter_totp_code;
                      }
                    }(),
                    actionButtonText: S.of(context).ok,
                    buttonAction: () {
                      result ? setup2FAViewModel.success() : null;
                      Navigator.of(context).pop(result);
                    },
                  );
                },
              );
            },
            text: S.of(context).continue_text,
            color: Theme.of(context).accentTextTheme.bodyLarge!.color!,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
