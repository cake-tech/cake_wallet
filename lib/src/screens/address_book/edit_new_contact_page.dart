import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';

class EditNewContactPage extends SheetPage {
  EditNewContactPage({
    required this.selectedParsedAddress,
    required this.contactViewModel,
  })  : _formKey = GlobalKey<FormState>(),
        _contactNameController = TextEditingController(
          text: selectedParsedAddress.profileName ?? '',
        );

  final ParsedAddress selectedParsedAddress;
  final ContactViewModel contactViewModel;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _contactNameController;

  @override
  String? get title => 'New Contact';

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedParsedAddress.addressSource == AddressSource.contact
                          ? 'Choose a contact name and icon'
                          : 'Contact info auto-detected from ${selectedParsedAddress.addressSource.label}',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            maxWidth: 44,
                            minHeight: 44,
                            maxHeight: 44,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                              child: Column(
                                children: [
                                  ImageUtil.getImageFromPath(
                                      imagePath: selectedParsedAddress.profileImageUrl,
                                      height: 24,
                                      width: 24,
                                      borderRadius: 30.0),
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
                        const SizedBox(width: 6),
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: InputDecoration(
                                isDense: true,
                                isCollapsed: true,
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                labelText: 'Address group name',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Theme.of(context).hintColor),
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Theme.of(context).hintColor),
                                fillColor: theme.colorScheme.surfaceContainer,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                    borderSide: BorderSide(color: Colors.transparent)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                  borderSide: BorderSide(color: Colors.transparent),
                                ),
                              ),
                              style: theme.textTheme.bodyMedium,
                              // validator: (value) {
                              //   final text = value?.trim() ?? '';
                              //   if (text.isEmpty) return 'Name cannot be empty';
                              //
                              //   final clash = contactViewModel.box.values.any(
                              //     (c) => c.name.toLowerCase() == text.toLowerCase(),
                              //   );
                              //   return clash ? 'Group with this name already exists' : null;
                              // },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: LoadingPrimaryButton(
                  text: 'Next',
                  width: 150,
                  height: 40,
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    if (contactViewModel.record != null) {
                      final record = contactViewModel.record!;
                      final isManual = selectedParsedAddress.addressSource == AddressSource.contact;

                      if (isManual) {
                        selectedParsedAddress.manualAddressByCurrencyMap?.forEach((cur, addr) {
                          record.setManualAddress(cur, cur.title, addr.trim());

                          final map = contactViewModel.manual.putIfAbsent(cur, () => {});
                          map[cur.title] = addr.trim();
                          contactViewModel.manual[cur] = Map.of(map);
                        });
                      } else {
                        final handleKey =
                        '${selectedParsedAddress.addressSource.label}-${selectedParsedAddress.handle}'
                            .trim();

                        selectedParsedAddress.parsedAddressByCurrencyMap.forEach((cur, addr) {
                          record.setParsedAddress(handleKey, cur, cur.title, addr.trim());

                          final block = contactViewModel.parsedBlocks.putIfAbsent(handleKey, () => {});
                          final map   = block.putIfAbsent(cur, () => {});
                          map[cur.title] = addr.trim();
                          contactViewModel.parsedBlocks[handleKey] =
                          {for (final e in block.entries) e.key: Map.of(e.value)};
                        });
                      }

                      record.original.lastChange = DateTime.now();
                      await record.original.save();

                      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                      return;
                    }
                    final localImg = await ImageUtil.saveAvatarLocally(
                        selectedParsedAddress.profileImageUrl);

                    final newContact = Contact.fromParsed(
                      selectedParsedAddress.copyWith(
                        profileName: _contactNameController.text.trim(),
                      ),
                      localImage: localImg,
                    );

                    contactViewModel.box.add(newContact);

                    final record = ContactRecord(contactViewModel.box, newContact);
                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        Routes.contactPage,
                        arguments: record,
                      );
                    }
                  },
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isLoading: false,
                  isDisabled: false,
                ),
              )
            ],
          ),
        ),
      );
  }
}
