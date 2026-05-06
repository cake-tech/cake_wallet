import 'package:flutter/material.dart';
import 'package:cw_starknet/cw_starknet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureStarknetRustInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('cw_starknet')),
        body: Center(
          child: const Text('Starknet Rust bridge initialized'),
        ),
      ),
    );
  }
}
