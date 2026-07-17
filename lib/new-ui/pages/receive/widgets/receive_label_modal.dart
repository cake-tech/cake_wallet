import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
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
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String label) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(label);
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(label);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTopBar(
                title: S.of(context).address_label,
                onLeadingPressed: Navigator.of(context).pop,
                onTrailingPressed: () {},
                leadingIcon: const Icon(Icons.close),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: S.of(context).address_label,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: defaultLabels
                          .map(
                            (label) => ActionChip(
                              label: Text(label),
                              onPressed: () {
                                _controller.text = label;
                                _controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: label.length),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(),
                    NewPrimaryButton(
                      text: S.of(context).save,
                      onPressed: () => _submit(_controller.text),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
