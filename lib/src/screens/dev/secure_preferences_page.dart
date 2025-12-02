import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/dev/secure_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DevSecurePreferencesPage extends BasePage {
  final DevSecurePreferences viewModel;

  DevSecurePreferencesPage(this.viewModel);

  @override
  String? get title => "[dev] secure preferences";

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.values.isEmpty) {
          return Center(child: Text("No secure preferences found"));
        }
        final keys = viewModel.keys;
        Map<String, dynamic> values = {};
        for (final key in keys) {
          values[key] = viewModel.get(key);
        }
        Map<String, PreferenceType> types = {};
        for (final key in keys) {
          types[key] = viewModel.getPreferenceType(key);
        }
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys[index];
            final type = types[key]!;
            return ListTile(
              onTap: () {
                Clipboard.setData(ClipboardData(text: key + ": " + values[key].toString()));
              },
              title: switch (type) {
                PreferenceType.bool => Text(key, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue)),
                PreferenceType.int => Text(key, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.green)),
                PreferenceType.double => Text(key, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.yellow)),
                PreferenceType.listString => Text(key, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.purple)),
                PreferenceType.string => Text(key),
                PreferenceType.unknown => Text(key),
              },
              subtitle: switch (type) {
                PreferenceType.bool => Text("bool: ${values[key]}"),
                PreferenceType.int => Text("int: ${values[key]}"),
                PreferenceType.double => Text("double: ${values[key]}"),
                PreferenceType.listString => values[key].isEmpty as bool ? Text("listString: []") : Text("listString:\n- ${values[key].join("\n- ")}"),
                PreferenceType.string => Text("string: ${values[key]}"),
                PreferenceType.unknown => Text("UNKNOWN(${values[key].runtimeType}): ${values[key]}"),
              },
            );
          },
        );
      },
    );
  }

}