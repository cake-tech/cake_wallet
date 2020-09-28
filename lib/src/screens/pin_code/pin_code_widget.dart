import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

class PinCodeWidget extends StatefulWidget {
  PinCodeWidget(
      {Key key,
      @required this.onFullPin,
      @required this.initialPinLength,
      this.onChangedPin,
      this.onChangedPinLength,
      this.hasLengthSwitcher})
      : super(key: key);

  final void Function(String pin, PinCodeState state) onFullPin;
  final void Function(String pin) onChangedPin;
  final void Function(int length) onChangedPinLength;
  final bool hasLengthSwitcher;
  final int initialPinLength;

  @override
  State<StatefulWidget> createState() => PinCodeState();
}

class PinCodeState<T extends PinCodeWidget> extends State<T> {
  static const defaultPinLength = fourPinLength;
  static const sixPinLength = 6;
  static const fourPinLength = 4;
  final _gridViewKey = GlobalKey();
  final _key = GlobalKey<ScaffoldState>();

  int pinLength;
  String pin;
  String title;
  double _aspectRatio;

  int currentPinLength() => pin.length;

  @override
  void initState() {
    super.initState();
    pinLength = widget.initialPinLength;
    pin = '';
    title = S.current.enter_your_pin;
    _aspectRatio = 0;
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
  }

  void setTitle(String title) => setState(() => this.title = title);

  void clear() => setState(() => pin = '');

  void reset() => setState(() {
        pin = '';
        pinLength = widget.initialPinLength;
        title = S.current.enter_your_pin;
      });

  void changePinLength(int length) {
    setState(() {
      pinLength = length;
      pin = '';
    });

    widget.onChangedPinLength?.call(length);
  }

  void setDefaultPinLength() => changePinLength(widget.initialPinLength);

  void calculateAspectRatio() {
    final renderBox =
        _gridViewKey.currentContext.findRenderObject() as RenderBox;
    final cellWidth = renderBox.size.width / 3;
    final cellHeight = renderBox.size.height / 4;

    if (cellWidth > 0 && cellHeight > 0) {
      _aspectRatio = cellWidth / cellHeight;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(key: _key, body: body(context));

  Widget body(BuildContext context) {
    final deleteIconImage = Image.asset(
      'assets/images/delete_icon.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );
    final faceImage = Image.asset(
      'assets/images/face.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    return Container(
      color: Theme.of(context).backgroundColor,
      padding: EdgeInsets.only(left: 40.0, right: 40.0, bottom: 40.0),
      child: Column(children: <Widget>[
        Spacer(flex: 2),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryTextTheme.title.color)),
        Spacer(flex: 3),
        Container(
          width: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(pinLength, (index) {
              const size = 10.0;
              final isFilled = pin.length > index ? pin[index] != null : false;

              return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? Theme.of(context).primaryTextTheme.title.color
                        : Theme.of(context)
                            .accentTextTheme
                            .body1
                            .color
                            .withOpacity(0.25),
                  ));
            }),
          ),
        ),
        Spacer(flex: 2),
        if (widget.hasLengthSwitcher) ...[
          FlatButton(
              onPressed: () {
                changePinLength(pinLength == PinCodeState.fourPinLength
                    ? PinCodeState.sixPinLength
                    : PinCodeState.fourPinLength);
              },
              child: Text(
                _changePinLengthText(),
                style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context)
                        .accentTextTheme
                        .body1
                        .decorationColor),
              ))
        ],
        Spacer(flex: 1),
        Flexible(
            flex: 24,
            child: Container(
                key: _gridViewKey,
                child: _aspectRatio > 0
                    ? GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        childAspectRatio: _aspectRatio,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(12, (index) {
                          const double marginRight = 15;
                          const double marginLeft = 15;

                          if (index == 9) {
                            return Container(
                              margin: EdgeInsets.only(
                                  left: marginLeft, right: marginRight),
                              child: FlatButton(
                                  onPressed: () => null,
                                  // (widget.hasLengthSwitcher ||
                                  //         !settingsStore
                                  //             .allowBiometricalAuthentication)
                                  //     ? null
                                  //     : () {
                                  // FIXME
//                                        if (authStore != null) {
//                                          WidgetsBinding.instance.addPostFrameCallback((_) {
//                                            final biometricAuth = BiometricAuth();
//                                            biometricAuth.isAuthenticated().then(
//                                                    (isAuth) {
//                                                  if (isAuth) {
//                                                    authStore.biometricAuth();
//                                                    _key.currentState.showSnackBar(
//                                                      SnackBar(
//                                                        content: Text(S.of(context).authenticated),
//                                                        backgroundColor: Colors.green,
//                                                      ),
//                                                    );
//                                                  }
//                                                }
//                                            );
//                                          });
//                                        }
//                                       },
                                  color: Theme.of(context).backgroundColor,
                                  shape: CircleBorder(),
                                  child: null
                                  // (widget.hasLengthSwitcher ||
                                  //         !settingsStore
                                  //             .allowBiometricalAuthentication)
                                  //     ? Offstage()
                                  //     : faceImage,
                                  ),
                            );
                          } else if (index == 10) {
                            index = 0;
                          } else if (index == 11) {
                            return Container(
                              margin: EdgeInsets.only(
                                  left: marginLeft, right: marginRight),
                              child: FlatButton(
                                onPressed: () => _pop(),
                                color: Theme.of(context).backgroundColor,
                                shape: CircleBorder(),
                                child: deleteIconImage,
                              ),
                            );
                          } else {
                            index++;
                          }

                          return Container(
                            margin: EdgeInsets.only(
                                left: marginLeft, right: marginRight),
                            child: FlatButton(
                              onPressed: () => _push(index),
                              color: Theme.of(context).backgroundColor,
                              shape: CircleBorder(),
                              child: Text('$index',
                                  style: TextStyle(
                                      fontSize: 30.0,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .title
                                          .color)),
                            ),
                          );
                        }),
                      )
                    : null))
      ]),
    );
  }

  void _push(int num) {
    setState(() {
      if (currentPinLength() >= pinLength) {
        return;
      }

      pin += num.toString();

      widget.onChangedPin(pin);

      if (pin.length == pinLength) {
        widget.onFullPin(pin, this);
      }
    });
  }

  void _pop() {
    if (currentPinLength() == 0) {
      return;
    }

    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  String _changePinLengthText() {
    return S.current.use +
        (pinLength == PinCodeState.fourPinLength
            ? '${PinCodeState.sixPinLength}'
            : '${PinCodeState.fourPinLength}') +
        S.current.digit_pin;
  }

  void _afterLayout(dynamic _) {
    setDefaultPinLength();
    calculateAspectRatio();
  }
}
