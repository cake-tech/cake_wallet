
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class HashChangeLogViewerPage extends StatelessWidget {
  const HashChangeLogViewerPage({super.key});

  Future<String?> loadHashLog() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hashed_identifier_changes.log'));
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hash Change Log')),
      body: FutureBuilder<String?>(
        future: loadHashLog(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final text = snap.data;
          if (text == null || text.isEmpty) {
            return Center(child: Text('No log records found.'));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              text,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
