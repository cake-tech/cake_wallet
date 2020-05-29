import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/auth/auth_state.dart';
import 'package:cake_wallet/src/stores/auth/auth_store.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/domain/common/biometric_auth.dart';

typedef OnAuthenticationFinished = void Function(bool, AuthPageState);

class AuthPage extends StatefulWidget {
  AuthPage({this.onAuthenticationFinished, this.closable = true});

  final OnAuthenticationFinished onAuthenticationFinished;
  final bool closable;

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final _key = GlobalKey<ScaffoldState>();
  final _pinCodeKey = GlobalKey<PinCodeState>();
  final _backArrowImageDarkTheme =
  Image.asset('assets/images/back_arrow_dark_theme.png');

  void changeProcessText(String text) {
    _key.currentState.showSnackBar(
        SnackBar(content: Text(text), backgroundColor: Colors.green));
  }

  void close() => Navigator.of(_key.currentContext).pop();

  @override
  Widget build(BuildContext context) {
    final authStore = Provider.of<AuthStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);

    if (settingsStore.allowBiometricalAuthentication) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final biometricAuth = BiometricAuth();
        biometricAuth.isAuthenticated().then(
                (isAuth) {
              if (isAuth) {
                authStore.biometricAuth();
                _key.currentState.showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).authenticated),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
        );
      });
    }

    reaction((_) => authStore.state, (AuthState state) {
      if (state is AuthenticatedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.onAuthenticationFinished != null) {
            widget.onAuthenticationFinished(true, this);
          } else {
            _key.currentState.showSnackBar(
              SnackBar(
                content: Text(S.of(context).authenticated),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }

      if (state is AuthenticationInProgress) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _key.currentState.showSnackBar(
            SnackBar(
              content: Text(S.of(context).authentication),
              backgroundColor: Colors.green,
            ),
          );
        });
      }

      if (state is AuthenticationFailure) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinCodeKey.currentState.clear();
          _key.currentState.hideCurrentSnackBar();
          _key.currentState.showSnackBar(
            SnackBar(
              content: Text(S.of(context).failed_authentication(state.error)),
              backgroundColor: Colors.red,
            ),
          );

          if (widget.onAuthenticationFinished != null) {
            widget.onAuthenticationFinished(false, this);
          }
        });
      }

      if (state is AuthenticationBanned) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinCodeKey.currentState.clear();
          _key.currentState.hideCurrentSnackBar();
          _key.currentState.showSnackBar(
            SnackBar(
              content: Text(S.of(context).failed_authentication(state.error)),
              backgroundColor: Colors.red,
            ),
          );

          if (widget.onAuthenticationFinished != null) {
            widget.onAuthenticationFinished(false, this);
          }
        });
      }
    });

    return Scaffold(
        key: _key,
        appBar: CupertinoNavigationBar(
          leading: widget.closable
          ? SizedBox(
            height: 37,
            width: 20,
            child: ButtonTheme(
              minWidth: double.minPositive,
              child: FlatButton(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  padding: EdgeInsets.all(0),
                  onPressed: () => Navigator.of(context).pop(),
                  child: _backArrowImageDarkTheme),
            ),
          )
          : Container(),
          backgroundColor: Theme.of(context).backgroundColor,
          border: null,
        ),
        resizeToAvoidBottomPadding: false,
        body: PinCode(
            (pin, _) => authStore.auth(
                password: pin.fold('', (ac, val) => ac + '$val')),
            false,
            _pinCodeKey));
  }
}
