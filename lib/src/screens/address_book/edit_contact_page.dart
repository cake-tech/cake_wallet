import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';

class EditContactPage extends SheetPage {
  EditContactPage({
    required this.contactViewModel,
  })  : _formKey = GlobalKey<FormState>(),
        _contactNameController = TextEditingController(text: contactViewModel.name) {}

  final ContactViewModel contactViewModel;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _contactNameController;

  @override
  String? get title => 'Edit Contact';

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget trailing(BuildContext context) {
    return RoundedIconButton(
      iconWidget: Image.asset('assets/images/trash_can_icon.png',
          width: 16, height: 16, color: Theme.of(context).colorScheme.onErrorContainer),
      fillColor: Theme.of(context).colorScheme.errorContainer,
      onPressed: () async {
        await contactViewModel.deleteContact();
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                        color: theme.colorScheme.surfaceContainer,
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
                        controller: _contactNameController,
                        labelText: 'Address group name',
                        fillColor: theme.colorScheme.surfaceContainer,
                        validator: contactViewModel.contactNameValidator),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                        if (!(_formKey.currentState?.validate() ?? false)) return;

                        contactViewModel.name = _contactNameController.text;
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
    );
  }
}
