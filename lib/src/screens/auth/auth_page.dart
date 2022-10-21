import 'package:cake_wallet/utils/show_bar.dart';
// import 'package:flushbar/flushbar.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:cake_wallet/view_model/auth_view_model.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/core/execution_state.dart';

typedef OnAuthenticationFinished = void Function(bool, AuthPageState);

class AuthPage extends StatefulWidget {
  AuthPage(this.authViewModel,
      {required this.onAuthenticationFinished,
        this.closable = true});

  final AuthViewModel authViewModel;
  final OnAuthenticationFinished onAuthenticationFinished;
  final bool closable;

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final _key = GlobalKey<ScaffoldState>();
  final _pinCodeKey = GlobalKey<PinCodeState>();
  final _backArrowImageDarkTheme =
      Image.asset('assets/images/close_button.png');
  ReactionDisposer? _reaction;
  // FIX-ME: replace Flushbar 
  // Flushbar<void>? _authBar;
  // Flushbar<void>? _progressBar;

  @override
  void initState() {
    _reaction ??=
        reaction((_) => widget.authViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onAuthenticationFinished(true, this);
        });
        setState(() {});
      }

      if (state is IsExecutingState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // FIX-ME: Changes related to flutter upgreade.
          //         Could be incorrect value for duration of auth bar
          // _authBar =
          //     createBar<void>(S.of(context).authentication, duration: Duration())
          //       ..show(context);
        });
      }

      if (state is FailureState) {
        print('X');
        print(state.error);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinCodeKey.currentState?.clear();
          // _authBar?.dismiss();
          showBar<void>(
              context, S.of(context).failed_authentication(state.error));

          if (widget.onAuthenticationFinished != null) {
            widget.onAuthenticationFinished(false, this);
          }
        });
      }

      if (state is AuthenticationBanned) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinCodeKey.currentState?.clear();
          // _authBar?.dismiss();
          showBar<void>(
              context, S.of(context).failed_authentication(state.error));

          if (widget.onAuthenticationFinished != null) {
            widget.onAuthenticationFinished(false, this);
          }
        });
      }
    });

    if (widget.authViewModel.isBiometricalAuthenticationAllowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(Duration(milliseconds: 100));
        await widget.authViewModel.biometricAuth();
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _reaction?.reaction.dispose();
    super.dispose();
  }

  void changeProcessText(String text) {
    // _authBar?.dismiss();
    // FIX-ME: Changes related to flutter upgreade.
          //         Could be incorrect value for duration of auth bar
    // _progressBar = createBar<void>(text, duration: Duration())
    //   ..show(_key.currentContext);
  }

  void hideProgressText() {
    // _progressBar?.dismiss();
    // _progressBar = null;
  }

  void close() {
    if (_key.currentContext == null) {
      throw Exception('Key context is null. Should be not happened');
    }

    // _authBar?.dismiss();
    // _progressBar?.dismiss();
    Navigator.of(_key.currentContext!).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        appBar: CupertinoNavigationBar(
            leading: widget.closable
                ? Container(
                    padding: EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 37,
                      width: 37,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child:  _backArrowImageDarkTheme,
                      ),
                    ))
                : Container(),
            backgroundColor: Theme.of(context).backgroundColor,
            border: null),
        resizeToAvoidBottomInset: false,
        body: PinCode((pin, _) => widget.authViewModel.auth(password: pin),
            (_) => null, widget.authViewModel.pinLength, false, _pinCodeKey));
  }
}
