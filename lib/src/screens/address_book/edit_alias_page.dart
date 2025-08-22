import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditAliasPage extends SheetPage {
  EditAliasPage({required this.contactViewModel, required this.handleKey});

  final ContactViewModel contactViewModel;
  final String handleKey;

  @override
  String? get title => 'Edit Alias';

  @override
  Widget trailing(BuildContext context) {
    return RoundedIconButton(
        iconWidget: Image.asset('assets/images/trash_can_icon.png',
            width: 16, height: 16, color: Theme.of(context).colorScheme.onErrorContainer),
        fillColor: Theme.of(context).colorScheme.errorContainer,
        onPressed: () async {
          await contactViewModel.deleteParsedBlock(handleKey);
          if (!context.mounted) return;
          final navigator = Navigator.of(context);
          (navigator.canPop() ? navigator : Navigator.of(context, rootNavigator: true)).pop();
        });
  }

  @override
  Widget body(BuildContext context) {
    final userName = handleKey.substring(handleKey.indexOf('-') + 1, handleKey.length);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              Text(userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoundedIconButton(
                          icon: Icons.copy_all_outlined,
                          onPressed: () async =>
                              await Clipboard.setData(ClipboardData(text: userName)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
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
                      onPressed: () {
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        S.of(context).done,
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
