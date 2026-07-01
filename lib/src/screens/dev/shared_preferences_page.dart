import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/view_model/dev/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DevSharedPreferencesPage extends BasePage {
  final DevSharedPreferences viewModel;

  DevSharedPreferencesPage(this.viewModel);

  @override
  String? get title => "[dev] shared preferences";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.add),
      onPressed: () => _showCreateDialog(context),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.sharedPreferences == null) {
          return Center(child: Text("No shared preferences found"));
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
              onLongPress: () {
                _showEditDialog(context, key, type, values[key]);
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

  void _showEditDialog(BuildContext context, String key, PreferenceType type, dynamic currentValue) {
    dynamic newValue = currentValue;
    bool isListString = type == PreferenceType.listString;
    List<String> listItems = isListString ? List<String>.from(currentValue as Iterable<dynamic>) : [];
    TextEditingController textController = TextEditingController(
        text: isListString ? '' : currentValue?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit $key'),
              content: SizedBox(
                width: double.maxFinite,
                height: double.maxFinite,
                child: SingleChildScrollView(
                  child: _buildDialogContent(
                    type, 
                    newValue, 
                    listItems, 
                    textController, 
                    (value) => setState(() => newValue = value),
                    (items) => setState(() => listItems = items),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmation(context, key);
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () async {
                    if (_validateAndUpdateValue(
                      context, 
                      type, 
                      textController, 
                      listItems, 
                      (value) => newValue = value
                    )) {
                      await viewModel.set(key, type, newValue);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Preference'),
          content: Text('Are you sure you want to delete "$key"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                viewModel.delete(key);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogContent(
    PreferenceType type,
    dynamic value,
    List<String> listItems,
    TextEditingController textController,
    Function(dynamic) onValueChanged,
    Function(List<String>) onListChanged,
  ) {
    return switch (type) {
      PreferenceType.bool => _buildBoolEditor(value as bool, onValueChanged),
      PreferenceType.int => _buildNumberEditor(textController, 'Integer value', true),
      PreferenceType.double => _buildNumberEditor(textController, 'Double value', false),
      PreferenceType.string => _buildTextEditor(textController),
      PreferenceType.listString => _buildListEditor(listItems, textController, onListChanged),
      PreferenceType.unknown => Text('Cannot edit unknown type'),
    };
  }

  Widget _buildBoolEditor(bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text('Value'),
      value: value,
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  Widget _buildTextEditor(TextEditingController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BaseTextFormField(
          controller: controller,
          hintText: 'String value',
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildNumberEditor(TextEditingController controller, String label, bool isInteger) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BaseTextFormField(
          controller: controller,
          hintText: label,
          keyboardType: isInteger 
              ? TextInputType.number 
              : TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
        ),
      ],
    );
  }

  Widget _buildListEditor(
    List<String> items, 
    TextEditingController controller,
    Function(List<String>) onListChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: ReorderableListView(
            shrinkWrap: true,
            children: [
              for (int i = 0; i < items.length; i++)
                ListTile(
                  key: Key('$i'),
                  title: Text(items[i]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      final newList = List<String>.from(items);
                      newList.removeAt(i);
                      onListChanged(newList);
                    },
                  ),
                )
            ],
            onReorder: (int oldIndex, int newIndex) {
              final newList = List<String>.from(items);
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = newList.removeAt(oldIndex);
              newList.insert(newIndex, item);
              onListChanged(newList);
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: BaseTextFormField(
                controller: controller,
                hintText: 'New item',
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final newList = List<String>.from(items);
                  newList.add(controller.text);
                  onListChanged(newList);
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  bool _validateAndUpdateValue(
    BuildContext context,
    PreferenceType type,
    TextEditingController controller,
    List<String> listItems,
    Function(dynamic) setNewValue,
  ) {
    switch (type) {
      case PreferenceType.int:
        if (controller.text.isNotEmpty) {
          try {
            setNewValue(int.parse(controller.text));
          } catch (e) {
            _showErrorMessage(context, 'Invalid integer value');
            return false;
          }
        }
        break;
      case PreferenceType.double:
        if (controller.text.isNotEmpty) {
          try {
            setNewValue(double.parse(controller.text));
          } catch (e) {
            _showErrorMessage(context, 'Invalid double value');
            return false;
          }
        }
        break;
      case PreferenceType.string:
        setNewValue(controller.text);
        break;
      case PreferenceType.listString:
        setNewValue(listItems);
        break;
      default:
        break;
    }
    return true;
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showCreateDialog(BuildContext context) {
    PreferenceType selectedType = PreferenceType.string;
    TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create Preference'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BaseTextFormField(
                      controller: keyController,
                      hintText: 'Preference Key',
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<PreferenceType>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: 'Type'),
                      items: [
                        DropdownMenuItem(value: PreferenceType.string, child: Text('String')),
                        DropdownMenuItem(value: PreferenceType.bool, child: Text('Boolean')),
                        DropdownMenuItem(value: PreferenceType.int, child: Text('Integer')),
                        DropdownMenuItem(value: PreferenceType.double, child: Text('Double')),
                        DropdownMenuItem(value: PreferenceType.listString, child: Text('List of Strings')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Create'),
                  onPressed: () {
                    if (keyController.text.isEmpty) {
                      _showErrorMessage(context, 'Key cannot be empty');
                      return;
                    }

                    viewModel.set(keyController.text, selectedType, switch (selectedType) {
                      PreferenceType.bool => false,
                      PreferenceType.int => 0,
                      PreferenceType.double => 0.0,
                      PreferenceType.string => '',
                      PreferenceType.listString => [],
                      PreferenceType.unknown => null,
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
