import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/services.dart';

class PinCodeWidget extends StatefulWidget {
  PinCodeWidget({
    required Key key,
    required this.onFullPin,
    required this.initialPinLength,
    required this.onChangedPin,
    required this.hasLengthSwitcher,
    this.onChangedPinLength,
  }) : super(key: key);

  final void Function(String pin, PinCodeState state) onFullPin;
  final void Function(String pin) onChangedPin;
  final void Function(int length)? onChangedPinLength;
  final bool hasLengthSwitcher;
  final int initialPinLength;

  @override
  State<StatefulWidget> createState() => PinCodeState();
}

class PinCodeState<T extends PinCodeWidget> extends State<T> {
  PinCodeState()
      : _aspectRatio = 0,
        pinLength = 0,
        pin = '',
        title = '';
  static const defaultPinLength = fourPinLength;
  static const sixPinLength = 6;
  static const fourPinLength = 4;
  final _gridViewKey = GlobalKey();
  final _key = GlobalKey<ScaffoldState>();
  late final FocusNode _focusNode;

  int pinLength;
  String pin;
  String title;
  double _aspectRatio;
  Flushbar<void>? _progressBar;

  int currentPinLength() => pin.length;

  @override
  void initState() {
    super.initState();
    pinLength = widget.initialPinLength;
    pin = '';
    title = S.current.enter_your_pin;
    _aspectRatio = 0;
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _afterLayout(_);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
    final renderBox = _gridViewKey.currentContext!.findRenderObject() as RenderBox;
    final cellWidth = renderBox.size.width / 3;
    final cellHeight = renderBox.size.height / 4;

    if (cellWidth > 0 && cellHeight > 0) {
      _aspectRatio = cellWidth / cellHeight;
    }

    setState(() {});
  }

  void changeProcessText(String text) {
    hideProgressText();
    _progressBar = createBar<void>(text, context, duration: null)..show(_key.currentContext!);
  }

  void close() {
    _progressBar?.dismiss();
    Navigator.of(_key.currentContext!).pop();
  }

  void hideProgressText() {
    _progressBar?.dismiss();
    _progressBar = null;
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(key: _key, body: body(context), resizeToAvoidBottomInset: false);

  Widget body(BuildContext context) {
    final deleteIconImage = Image.asset(
      'assets/images/delete_icon.png',
      color: Theme.of(context).colorScheme.primary,
    );

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          if (keyEvent.logicalKey.keyLabel == "Backspace") {
            _pop();
            return;
          }
          int? number = int.tryParse(keyEvent.character ?? '');
          if (number != null) {
            _push(number);
          }
        }
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.only(left: 40.0, right: 40.0, bottom: 60.0),
        child: Column(
          children: <Widget>[
            Spacer(flex: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
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
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      ));
                }),
              ),
            ),
            Spacer(flex: 3),
            if (widget.hasLengthSwitcher) ...[
              TextButton(
                onPressed: () {
                  changePinLength(pinLength == PinCodeState.fourPinLength
                      ? PinCodeState.sixPinLength
                      : PinCodeState.fourPinLength);
                },
                child: Text(
                  _changePinLengthText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              )
            ],
            Spacer(flex: 1),
            Flexible(
              flex: 24,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
                  ),
                  child: Container(
                    key: _gridViewKey,
                    child: _aspectRatio > 0
                        ? ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              childAspectRatio: _aspectRatio,
                              physics: const NeverScrollableScrollPhysics(),
                              children: List.generate(12, (index) {
                                const double marginRight = 8;
                                const double marginLeft = 8;

                                if (index == 9) {
                                  // Empty container
                                  return Container(
                                    margin: EdgeInsets.only(left: marginLeft, right: marginRight),
                                  );
                                } else if (index == 10) {
                                  index = 0;
                                } else if (index == 11) {
                                  return MergeSemantics(
                                    child: Container(
                                      margin: EdgeInsets.only(left: marginLeft, right: marginRight),
                                      child: Semantics(
                                        label: S.of(context).delete,
                                        button: true,
                                        onTap: () => _pop(),
                                        child: TextButton(
                                          onPressed: () => _pop(),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                                            shape: CircleBorder(),
                                          ),
                                          child: deleteIconImage,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  index++;
                                }

                                return Container(
                                  margin: EdgeInsets.only(left: marginLeft, right: marginRight),
                                  child: TextButton(
                                    key: ValueKey('pin_code_button_${index}_key'),
                                    onPressed: () => _push(index),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                                      shape: CircleBorder(),
                                    ),
                                    child: Text('$index',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 30,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            )),
                                  ),
                                );
                              }),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
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
