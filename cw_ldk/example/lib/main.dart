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
  String _testLDK = "foobar";
  String _testBlocking = "foobar";

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

    final testLDK =
        await CwLdk.testLDKAsync("polaruser:polarpass@192.168.0.11:18443");
    
    CwLdk.ldkChannels();
    CwLdk.ffiChannels();

    // final path = await CwLdk.createFolderInAppDocDir(".ldk");
    // await CwLdk.listFilesInFolder(".ldk");
    // await CwLdk.deleteFolder(".ldk");

    // final path = await CwLdk.getAppDocDirPath();
    // final testBlocking = CwLdk.testLDKBlocking(path + "/.ldk");

    // await CwLdk.deleteFolder(".ldk");

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _testLDK = testLDK;
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
                Text('test_LDK: $_testLDK'),
                // Text('test_Blocking: $_testBlocking'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
