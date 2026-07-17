import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";

class ReceiveLabelModal extends StatefulWidget {
  const ReceiveLabelModal({
    required this.initialLabel,
    required this.onSubmit,
    super.key,
  });

  final String initialLabel;
  final Future<void> Function(String label) onSubmit;

  @override
  State<ReceiveLabelModal> createState() => _ReceiveLabelModalState();
}

class _ReceiveLabelModalState extends State<ReceiveLabelModal> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = widget.initialLabel;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_controller.text);
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(_controller.text);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLabels = <String>[
      S.of(context).donation,
      S.of(context).savings,
      S.of(context).business,
      S.of(context).mining,
      S.of(context).salary,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            spacing: 24,
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: S.of(context).label_address,
                leadingIcon: const Icon(Icons.close),
                onLeadingPressed: Navigator.of(context).pop,
                onTrailingPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  spacing: 24,
                  children: [
                    Text(
                      S.of(context).address_label_explainer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    NewListSections(
                      sections: {
                        "": [ListItemTextField(keyValue: "label", label: S.of(context).label)],
                      },
                      controllers: {"label": _controller},
                    ),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: defaultLabels.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                _controller.text = defaultLabels[index];
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Center(
                                  child: Text(
                                    defaultLabels[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    NewPrimaryButton(
                      isLoading: _saving,
                      onPressed: _submit,
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
