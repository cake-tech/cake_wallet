import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/root_dir.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> handleSqliteError(final dynamic error, final StackTrace stackTrace) async {
  try {
    final f = await sqliteDebugMarkerFile();
    f.createSync();
  } catch (_) {}
  runApp(
    SqliteErrorHandlerApp(
      error: error,
      stackTrace: stackTrace,
    ),
  );
  await Future.delayed(Duration(hours: 24));
}

class SqliteErrorHandlerApp extends StatelessWidget {
  const SqliteErrorHandlerApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final dynamic error;
  final StackTrace? stackTrace;
  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cake Wallet Crash',
      themeMode: ThemeMode.light,
      home: SqliteErrorHandler(
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class SqliteErrorHandler extends StatefulWidget {
  SqliteErrorHandler({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final dynamic error;
  final StackTrace? stackTrace;

  @override
  State<SqliteErrorHandler> createState() => _SqliteErrorHandlerState();
}

class _SqliteErrorHandlerState extends State<SqliteErrorHandler> {
  String log = "";

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sqlite Recovery Screen"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildNotice(),
          ),
        ),
      ),
    );
  }

  Widget _text(final dynamic element) {
    return SelectableText(
      element.toString(),
    );
  }

  void _dbgRemoveDebugMarker() async {
    final f = await sqliteDebugMarkerFile();
    f.delete();
  }

  void _corruptTheDb() async {
    final dbFile = File("${(await getAppDir()).path}/cake.db");
    await writeBytesToFile(dbFile);
  }

  void _dumpDb() async {
    try {
      final dbFile = File("${(await getAppDir()).path}/cake.db");
      final jsonText = JsonEncoder.withIndent("    ").convert(await dumpCustomDb(dbFile.path));
      setState(() {
        log = jsonText;
      });
    } catch (e, s) {
      setState(() {
        log = """
e: $e

s: $s
""";
      });
    }
  }

  void _removeDb() async {
    try {
      File("${(await getAppDir()).path}/cake.db.old").deleteSync();
    } catch (_) {}
    final dbFile = File("${(await getAppDir()).path}/cake.db");
    dbFile.renameSync("${(await getAppDir()).path}/cake.db.old");
  }

  List<Widget> _debugOptions() {
    return [
      _debugButton("Remove debug marker", _dbgRemoveDebugMarker),
      if (kDebugMode || kProfileMode) _debugButton("[DO NOT PRESS] Corrupt the DB", _corruptTheDb),
      _debugButton("Remove DB", _removeDb),
      _debugButton("Dump DB", _dumpDb),
    ];
  }

  Widget _debugButton(String text, VoidCallback callback) {
    return ElevatedButton(
      onPressed: callback,
      child: Text(text),
    );
  }

  List<Widget> _buildNotice() {
    return [
      _text("""Critical error occured in SQLite
This is very rare, usually caused by the device killing the app before it finishes writing file.
Here you can recover the database or recreate it to regain access to your wallets.
During this process some of the metadata may get lost.
Please contact support@cakewallet.com if you need any help."""),
      Divider(),
      ..._debugOptions(),
      if (log.isNotEmpty) ...[
        Divider(),
        SelectableText(
          log,
          style: TextStyle(
            fontSize: 8,
          ),
        ),
      ],
      Divider(),
      _text(widget.error),
      Divider(),
      _text(widget.stackTrace),
    ];
  }
}

Future<void> writeBytesToFile(File file) async {
  const int seek = 5;
  const int count = 50000;
  final raf = await file.open(mode: FileMode.writeOnlyAppend);
  try {
    await raf.setPosition(seek);
    final zeros = Uint8List.fromList(List.generate(count, (_) => 0x42));
    await raf.writeFrom(zeros);
  } finally {
    await raf.close();
  }
}
