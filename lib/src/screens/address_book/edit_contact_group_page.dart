import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditContactGroupPage extends BasePage {
  EditContactGroupPage({
    required this.contactViewModel,
  })  : _formKey = GlobalKey<FormState>(),
        _groupLabelCtl = TextEditingController(text: contactViewModel.name) {
    _groupLabelCtl.addListener(() {
      contactViewModel.name = _groupLabelCtl.text;
    });
  }

  final ContactViewModel contactViewModel;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _groupLabelCtl;

  @override
  String? get title => 'Edit Contact';

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        reverse: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                //edit avatar
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  maxWidth: 44,
                                  minHeight: 44,
                                  maxHeight: 44,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: fillColor,
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: Image(
                                            width: 24,
                                            height: 24,
                                            image: contactViewModel.avatar,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text('Icon',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 8,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Form(
                                key: _formKey,
                                child: StandardTextFormFieldWidget(
                                  controller: _groupLabelCtl,
                                  labelText: 'Address group name',
                                  fillColor: fillColor,
                                  addressValidator: (value) {
                                    // final text = value?.trim() ?? '';
                                    // if (text.isEmpty) return 'Name cannot be empty';
                                    //
                                    // final clash = contactViewModel.box.values.any(
                                    //   (c) =>
                                    //       c.name.toLowerCase() == text.toLowerCase() &&
                                    //       c.key != contactViewModel.contactRecord?.original.key,
                                    // );
                                    // return clash ? 'Group with this name already exists' : null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    contactViewModel.userHandles.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              'No alias services found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Observer(builder: (_) {
                            final userHandlesList = contactViewModel.userHandles.toList();
                            return Column(
                              children: [
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Alias Services',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ListView.separated(
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: userHandlesList.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final item = userHandlesList[index];
                                    return ListTile(
                                      title: Text(item.src?.label ?? '',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color:
                                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                              )),
                                      subtitle: Text(item.label,
                                          style: Theme.of(context).textTheme.bodySmall),
                                      trailing: RoundedIconButton(
                                          icon: Icons.delete_outline_rounded,
                                          onPressed: () {
                                            contactViewModel.deleteParsedBlock(item.handleKey);
                                          },
                                          iconSize: 20,
                                          width: 28,
                                          height: 28),
                                      tileColor: fillColor,
                                      dense: true,
                                      visualDensity: VisualDensity(horizontal: 0, vertical: -3),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                      leading: ImageUtil.getImageFromPath(
                                          imagePath: item.src?.iconPath ?? '',
                                          height: 24,
                                          width: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: RoundedIconButton(
                            icon: Icons.delete_outline_rounded,
                            onPressed: () async {
                              await contactViewModel.deleteContact();
                              if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 40,
                            height: 40,
                            iconSize: 30,
                            fillColor: Theme.of(context).colorScheme.errorContainer),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fillColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            S.of(context).cancel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              return;
                            }
                            contactViewModel.name = _groupLabelCtl.text;
                            await contactViewModel.saveContactInfo();

                            if (context.mounted) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            S.of(context).save,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
