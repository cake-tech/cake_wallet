import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cake_wallet/generated/i18n.dart';

class TimerWidget extends StatefulWidget {
  final DateTime expiratedAt;
  final Color color;

  TimerWidget(this.expiratedAt, {this.color = Colors.black});

  @override
  createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  int _leftSeconds;
  int _minutes;
  int _seconds;
  bool _isExpired;
  Timer _timer;

  TimerWidgetState();

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
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isExpired
        ? Text(S.of(context).expired, style: TextStyle(fontSize: 14.0, color: Colors.red))
        : Text(
            S.of(context).time(_minutes.toString(), _seconds.toString()),
            style: TextStyle(fontSize: 14.0, color: widget.color),
          );
  }

  void _recalculate() {
    _minutes = _leftSeconds ~/ 60;
    _seconds = _leftSeconds % 60;
  }
}
