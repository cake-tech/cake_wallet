import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cake_wallet/generated/i18n.dart';

class TimerWidget extends StatefulWidget {
  TimerWidget(this.expiratedAt, {this.color = Colors.black});

  final DateTime expiratedAt;
  final Color color;

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  TimerWidgetState()
    : _leftSeconds = 0,
    _minutes = 0,
    _seconds = 0,
    _isExpired = false;

  int _leftSeconds;
  int _minutes;
  int _seconds;
  bool _isExpired;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final start = DateTime.now();
    _isExpired = false;
    _leftSeconds = widget.expiratedAt.difference(start).inSeconds;
    _recalculate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_isExpired) {
          timer.cancel();
        }

        _leftSeconds--;
        _isExpired = _leftSeconds <= 0;
        _recalculate();
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isExpired
        ? Text(S.of(context).expired,
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.red))
        : Text(
            S.of(context).time(_minutes.toString(), _seconds.toString()),
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: widget.color),
          );
  }

  void _recalculate() {
    _minutes = _leftSeconds ~/ 60;
    _seconds = _leftSeconds % 60;
  }
}
