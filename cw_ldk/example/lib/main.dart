import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:cw_ldk/cw_ldk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _startLDK = "foobar";
  final _mnomonicKeyPhrase =
      "stool outside acoustic correct craft attitude scheme urge grape again chalk gas";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;

    try {
      platformVersion = await CwLdk.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // setup pointer for isolate communication.
    CwLdk.storeDartPostCobject(NativeApi.postCObject);

    final startLDK = await CwLdk.startLDK(
        "polaruser:polarpass@192.168.0.13:18443",
        9732,
        "regtest",
        "hellolightning",
        "0.0.0.0",
        _mnomonicKeyPhrase);

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _startLDK = startLDK;
      // _testBlocking = testBlocking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Running on: $_platformVersion\n'),
                Text('startLDK: $_startLDK'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
