import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/auth/auth_state.dart';
import 'package:cake_wallet/src/stores/auth/auth_store.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code.dart';


class AuthPage extends StatefulWidget {
  final Function(bool, AuthPageState) onAuthenticationFinished;
  final bool closable;

  AuthPage({this.onAuthenticationFinished, this.closable = true});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final _key = GlobalKey<ScaffoldState>();
  final _pinCodeKey = GlobalKey<PinCodeState>();

  void changeProcessText(String text) {
    _key.currentState.showSnackBar(
        SnackBar(content: Text(text), backgroundColor: Colors.green));
  }

  void close() => Navigator.of(_key.currentContext).pop();

  @override
  Widget build(BuildContext context) {
    final authStore = Provider.of<AuthStore>(context);

    reaction((_) => authStore.state, (state) {
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

      if (state is AuthenticationFailure || state is AuthenticationBanned) {
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
          leading: widget.closable ? CloseButton() : Container(),
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
